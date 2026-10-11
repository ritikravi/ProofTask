import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/challenges/challenge_generator.dart';
import '../features/verification/verification_service.dart';
import 'api_client.dart';
import 'llm.dart';
import 'models.dart';

final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

const _uuid = Uuid();

// -------------------------------------------------------------- secrets

/// API key / GitHub token. Keychain/Keystore on devices; browser storage on
/// web (no secure enclave there). Values are cached after [open] so reads are sync.
class SecretStore {
  SecretStore._(this._prefs, this._secure, this._cache);

  /// Plain in-memory/prefs store for tests.
  factory SecretStore.memory(SharedPreferences prefs) =>
      SecretStore._(prefs, null, {});

  final SharedPreferences _prefs;
  final FlutterSecureStorage? _secure;
  final Map<String, String> _cache;

  static const keys = ['api_key', 'grok_key', 'github_token', 'auth_token'];

  static Future<SecretStore> open(SharedPreferences prefs) async {
    final secure = kIsWeb ? null : const FlutterSecureStorage();
    final cache = <String, String>{};
    for (final k in keys) {
      String? v;
      if (secure != null) {
        try {
          v = await secure.read(key: k);
          // One-time migration from plain prefs.
          final legacy = prefs.getString(k);
          if ((v == null || v.isEmpty) && legacy != null && legacy.isNotEmpty) {
            await secure.write(key: k, value: legacy);
            await prefs.remove(k);
            v = legacy;
          }
        } on Object {
          v = prefs.getString(k);
        }
      } else {
        v = prefs.getString(k);
      }
      cache[k] = v ?? '';
    }
    return SecretStore._(prefs, secure, cache);
  }

  String get(String key) => _cache[key] ?? '';

  void set(String key, String value) {
    _cache[key] = value;
    final secure = _secure;
    if (secure == null) {
      _prefs.setString(key, value);
      return;
    }
    secure.write(key: key, value: value).catchError((Object _) {
      _prefs.setString(key, value);
    });
  }
}

final secretsProvider = Provider<SecretStore>(
  (ref) => SecretStore.memory(ref.read(prefsProvider)),
);

// ---------------------------------------------------------------- tasks

class TasksNotifier extends Notifier<List<Task>> {
  static const _key = 'tasks_v1';

  @override
  List<Task> build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() => ref
      .read(prefsProvider)
      .setString(_key, jsonEncode(state.map((t) => t.toJson()).toList()));

  void add(String title, String definition, {
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
    String acceptanceCriteria = '',
    List<String> requiredEvidenceTypes = const [],
  }) {
    state = [
      Task(
        id: _uuid.v4(),
        title: title.trim(),
        definition: definition.trim(),
        createdAt: DateTime.now(),
        deadline: deadline,
        priority: priority,
        acceptanceCriteria: acceptanceCriteria,
        requiredEvidenceTypes: requiredEvidenceTypes,
      ),
      ...state,
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  void _replace(Task t) {
    state = [for (final x in state) x.id == t.id ? t : x];
    _persist();
  }

  /// Records the attempt; completes the task or assigns a challenge.
  void recordAttempt(String taskId, Evidence evidence, Outcome o) {
    final task = state.firstWhere((t) => t.id == taskId);
    final attempt = Attempt(
      id: _uuid.v4(),
      type: evidence.type,
      evidence: evidence.value,
      hash: o.hash,
      verdict: o.verdict,
      confidence: o.confidence,
      reasoning: o.reasoning,
      message: o.message,
      createdAt: DateTime.now(),
      usedLlm: o.usedLlm,
    );
    final next = task.copyWith(attempts: [...task.attempts, attempt]);
    if (o.passed) {
      _replace(
        next.copyWith(
          status: TaskStatus.verified,
          completedAt: DateTime.now(),
          clearChallenge: true,
        ),
      );
    } else if (o.verdict == Verdict.inconclusive) {
      // Couldn't check (unreachable link, no AI for images): no punishment.
      _replace(next);
    } else {
      _replace(
        next.copyWith(
          challenge: generateChallenge(
            failedCount(next),
            DateTime.now(),
            seed: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
    }
  }

  /// Replaces the verdict of the latest attempt after a dispute re-judge.
  void applyDispute(String taskId, Outcome o) {
    final task = state.firstWhere((t) => t.id == taskId);
    if (task.attempts.isEmpty) return;
    final last = task.attempts.last.copyWith(
      verdict: o.verdict,
      confidence: o.confidence,
      reasoning: 'Disputed. ${o.reasoning}',
      message: o.message,
    );
    final attempts = [
      ...task.attempts.sublist(0, task.attempts.length - 1),
      last,
    ];
    if (o.passed) {
      _replace(
        task.copyWith(
          attempts: attempts,
          status: TaskStatus.verified,
          completedAt: DateTime.now(),
          clearChallenge: true,
        ),
      );
    } else {
      _replace(task.copyWith(attempts: attempts));
    }
  }

  void clearChallenge(String taskId) {
    final task = state.firstWhere((t) => t.id == taskId);
    _replace(task.copyWith(clearChallenge: true));
  }

  /// "Break it down": adds subtasks and releases the lock on the parent.
  void addSubtasks(String parentId, List<String> titles) {
    final parent = state.firstWhere((t) => t.id == parentId);
    final now = DateTime.now();
    final subs = [
      for (final t in titles)
        Task(
          id: _uuid.v4(),
          title: t,
          definition: 'Part of: ${parent.title}',
          createdAt: now,
        ),
    ];
    state = [
      ...subs,
      ...state.map(
        (t) => t.id == parentId ? t.copyWith(clearChallenge: true) : t,
      ),
    ];
    _persist();
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

// ------------------------------------------------------------- settings

class AppSettings {
  const AppSettings({
    this.apiKey = '',
    this.grokKey = '',
    this.githubToken = '',
    this.roastLevel = 1,
    this.strictness = 1,
    this.notToday = false,
    this.reduceMotion = false,
    this.onboarded = false,
    this.backendUrl = '',
    this.useBackend = false,
    this.authToken = '',
  });

  final String apiKey;

  /// xAI Grok API key — takes priority over Anthropic when set.
  final String grokKey;

  /// Optional GitHub PAT for private-repo commit proof.
  final String githubToken;

  /// 0 gentle sigh · 1 passive-aggressive · 2 disappointed parent · 3 HR.
  final int roastLevel;

  /// 0..3, raises the confidence needed to pass.
  final int strictness;
  final bool notToday;
  final bool reduceMotion;
  final bool onboarded;

  /// Backend API base URL (e.g. http://localhost:5000)
  final String backendUrl;

  /// Use backend API instead of local verification
  final bool useBackend;

  /// JWT auth token for backend
  final String authToken;

  bool get hasKey => grokKey.trim().isNotEmpty || apiKey.trim().isNotEmpty;
  bool get hasBackend => useBackend && backendUrl.trim().isNotEmpty;

  AppSettings copyWith({
    String? apiKey,
    String? grokKey,
    String? githubToken,
    int? roastLevel,
    int? strictness,
    bool? notToday,
    bool? reduceMotion,
    bool? onboarded,
    String? backendUrl,
    bool? useBackend,
    String? authToken,
  }) => AppSettings(
    apiKey: apiKey ?? this.apiKey,
    grokKey: grokKey ?? this.grokKey,
    githubToken: githubToken ?? this.githubToken,
    roastLevel: roastLevel ?? this.roastLevel,
    strictness: strictness ?? this.strictness,
    notToday: notToday ?? this.notToday,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    onboarded: onboarded ?? this.onboarded,
    backendUrl: backendUrl ?? this.backendUrl,
    useBackend: useBackend ?? this.useBackend,
    authToken: authToken ?? this.authToken,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.read(prefsProvider);
    final secrets = ref.read(secretsProvider);
    return AppSettings(
      apiKey: secrets.get('api_key'),
      grokKey: secrets.get('grok_key'),
      githubToken: secrets.get('github_token'),
      roastLevel: p.getInt('roast_level') ?? 1,
      strictness: p.getInt('strictness') ?? 1,
      notToday: p.getBool('not_today') ?? false,
      reduceMotion: p.getBool('reduce_motion') ?? false,
      onboarded: p.getBool('onboarded') ?? false,
      backendUrl: p.getString('backend_url') ?? '',
      useBackend: p.getBool('use_backend') ?? false,
      authToken: secrets.get('auth_token'),
    );
  }

  void update(AppSettings s) {
    final p = ref.read(prefsProvider);
    final secrets = ref.read(secretsProvider);
    if (s.apiKey != state.apiKey) secrets.set('api_key', s.apiKey.trim());
    if (s.grokKey != state.grokKey) secrets.set('grok_key', s.grokKey.trim());
    if (s.githubToken != state.githubToken) {
      secrets.set('github_token', s.githubToken.trim());
    }
    if (s.authToken != state.authToken) {
      secrets.set('auth_token', s.authToken.trim());
    }
    state = s;
    p.setInt('roast_level', s.roastLevel);
    p.setInt('strictness', s.strictness);
    p.setBool('not_today', s.notToday);
    p.setBool('reduce_motion', s.reduceMotion);
    p.setBool('onboarded', s.onboarded);
    p.setString('backend_url', s.backendUrl);
    p.setBool('use_backend', s.useBackend);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ------------------------------------------------------ AI + verification

/// Grok is preferred when a key is set; falls back to Anthropic; null = offline.
/// Override in tests.
final llmProvider = Provider<LlmProvider?>((ref) {
  final s = ref.watch(settingsProvider.select((s) => (s.grokKey, s.apiKey)));
  final grok = s.$1.trim();
  final anthropic = s.$2.trim();
  if (grok.isNotEmpty) return GrokProvider(grok);
  if (anthropic.isNotEmpty) return AnthropicProvider(anthropic);
  return null;
});

final verificationServiceProvider = Provider<VerificationService>((ref) {
  final s = ref.watch(settingsProvider);
  return VerificationService(
    llm: ref.watch(llmProvider),
    strictness: s.strictness,
    roastLevel: s.roastLevel,
    notToday: s.notToday,
    githubToken: s.githubToken,
  );
});

// ----------------------------------------------------------- api client

/// Optional backend API client when backend mode is enabled.
final apiClientProvider = Provider<ApiClient?>((ref) {
  final s = ref.watch(settingsProvider);
  if (!s.hasBackend) return null;
  return ApiClient(
    baseUrl: s.backendUrl,
    token: s.authToken.isEmpty ? null : s.authToken,
  );
});
