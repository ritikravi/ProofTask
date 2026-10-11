import 'dart:typed_data';

enum Verdict { pass, weak, fail, inconclusive }

enum EvidenceType { text, screenshot, url, commit }

/// What the user submits as proof. [value] is the text, URL or file name.
class Evidence {
  const Evidence(this.type, this.value, {this.bytes, this.mime});
  final EvidenceType type;
  final String value;
  final Uint8List? bytes;
  final String? mime;
}

enum ChallengeType { typing, quiz, timer, explain, micro, cooldown }

enum TaskStatus { todo, inProgress, pendingVerification, needsRevision, verified, blocked, done }

/// Priority level for a task
enum TaskPriority { low, medium, high }

class Challenge {
  const Challenge({
    required this.type,
    required this.prompt,
    required this.seconds,
    this.dueAt,
    this.detail = '',
  });

  final ChallengeType type;
  final String prompt;
  final int seconds;

  /// Cooldown only: moment the lock ends.
  final DateTime? dueAt;

  /// Type-specific extra (e.g. the micro-task to perform).
  final String detail;

  Map<String, dynamic> toJson() => {
    'detail': detail,
    'type': type.name,
    'prompt': prompt,
    'seconds': seconds,
    'dueAt': dueAt?.toIso8601String(),
  };

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    type: ChallengeType.values.byName(j['type'] as String),
    prompt: j['prompt'] as String,
    seconds: j['seconds'] as int,
    detail: (j['detail'] as String?) ?? '',
    dueAt: j['dueAt'] == null ? null : DateTime.parse(j['dueAt'] as String),
  );
}

class Attempt {
  const Attempt({
    required this.id,
    this.type = EvidenceType.text,
    required this.evidence,
    required this.hash,
    required this.verdict,
    required this.confidence,
    required this.reasoning,
    required this.message,
    required this.createdAt,
    this.usedLlm = false,
  });

  final String id;
  final bool usedLlm;
  final EvidenceType type;
  final String evidence;
  final String hash;
  final Verdict verdict;
  final double confidence;
  final String reasoning;

  /// Roast (fail/weak) or praise (pass).
  final String message;
  final DateTime createdAt;

  Attempt copyWith({
    Verdict? verdict,
    double? confidence,
    String? reasoning,
    String? message,
  }) => Attempt(
    id: id,
    type: type,
    evidence: evidence,
    hash: hash,
    verdict: verdict ?? this.verdict,
    confidence: confidence ?? this.confidence,
    reasoning: reasoning ?? this.reasoning,
    message: message ?? this.message,
    createdAt: createdAt,
    usedLlm: usedLlm,
  );

  Map<String, dynamic> toJson() => {
    'usedLlm': usedLlm,
    'id': id,
    'type': type.name,
    'evidence': evidence,
    'hash': hash,
    'verdict': verdict.name,
    'confidence': confidence,
    'reasoning': reasoning,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Attempt.fromJson(Map<String, dynamic> j) => Attempt(
    id: j['id'] as String,
    usedLlm: (j['usedLlm'] as bool?) ?? false,
    type: EvidenceType.values.byName((j['type'] as String?) ?? 'text'),
    evidence: j['evidence'] as String,
    hash: j['hash'] as String,
    verdict: Verdict.values.byName(j['verdict'] as String),
    confidence: (j['confidence'] as num).toDouble(),
    reasoning: j['reasoning'] as String,
    message: j['message'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.definition,
    required this.createdAt,
    this.status = TaskStatus.todo,
    this.attempts = const [],
    this.challenge,
    this.completedAt,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.acceptanceCriteria = '',
    this.requiredEvidenceTypes = const [],
    this.expectedOutcome = '',
    this.verificationPolicy = 'any',
  });

  final String id;
  final String title;
  final String definition;
  final DateTime createdAt;
  final TaskStatus status;
  final List<Attempt> attempts;

  /// Non-null = task locked until challenge cleared.
  final Challenge? challenge;
  final DateTime? completedAt;

  // Extended fields
  final DateTime? deadline;
  final TaskPriority priority;
  final String acceptanceCriteria;
  final List<String> requiredEvidenceTypes;
  final String expectedOutcome;
  final String verificationPolicy;

  bool get isDone => status == TaskStatus.done || status == TaskStatus.verified;
  bool get isLocked => challenge != null;

  Task copyWith({
    TaskStatus? status,
    List<Attempt>? attempts,
    Challenge? challenge,
    bool clearChallenge = false,
    DateTime? completedAt,
    DateTime? deadline,
    TaskPriority? priority,
    String? acceptanceCriteria,
    List<String>? requiredEvidenceTypes,
    String? expectedOutcome,
    String? verificationPolicy,
  }) => Task(
    id: id,
    title: title,
    definition: definition,
    createdAt: createdAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    challenge: clearChallenge ? null : (challenge ?? this.challenge),
    completedAt: completedAt ?? this.completedAt,
    deadline: deadline ?? this.deadline,
    priority: priority ?? this.priority,
    acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
    requiredEvidenceTypes: requiredEvidenceTypes ?? this.requiredEvidenceTypes,
    expectedOutcome: expectedOutcome ?? this.expectedOutcome,
    verificationPolicy: verificationPolicy ?? this.verificationPolicy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'definition': definition,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'challenge': challenge?.toJson(),
    'completedAt': completedAt?.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'priority': priority.name,
    'acceptanceCriteria': acceptanceCriteria,
    'requiredEvidenceTypes': requiredEvidenceTypes,
    'expectedOutcome': expectedOutcome,
    'verificationPolicy': verificationPolicy,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String? ?? j['_id'] as String,
    title: j['title'] as String,
    definition: (j['definition'] as String?) ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    status: _parseStatus(j['status'] as String? ?? 'todo'),
    attempts: (j['attempts'] as List? ?? [])
        .map((a) => Attempt.fromJson(a as Map<String, dynamic>))
        .toList(),
    challenge: j['challenge'] == null
        ? null
        : Challenge.fromJson(j['challenge'] as Map<String, dynamic>),
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.parse(j['completedAt'] as String),
    deadline: j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String),
    priority: _parsePriority(j['priority'] as String? ?? 'medium'),
    acceptanceCriteria: (j['acceptanceCriteria'] as String?) ?? '',
    requiredEvidenceTypes: List<String>.from(j['requiredEvidenceTypes'] as List? ?? []),
    expectedOutcome: (j['expectedOutcome'] as String?) ?? '',
    verificationPolicy: (j['verificationPolicy'] as String?) ?? 'any',
  );

  static TaskStatus _parseStatus(String s) {
    // Handle both camelCase (client) and snake_case variants (backend)
    const map = {
      'todo': TaskStatus.todo,
      'inProgress': TaskStatus.inProgress,
      'in_progress': TaskStatus.inProgress,
      'pendingVerification': TaskStatus.pendingVerification,
      'pending_verification': TaskStatus.pendingVerification,
      'needsRevision': TaskStatus.needsRevision,
      'needs_revision': TaskStatus.needsRevision,
      'verified': TaskStatus.verified,
      'blocked': TaskStatus.blocked,
      'done': TaskStatus.done,
    };
    return map[s] ?? TaskStatus.todo;
  }

  static TaskPriority _parsePriority(String s) =>
      TaskPriority.values.firstWhere((p) => p.name == s, orElse: () => TaskPriority.medium);
}

/// Result of running evidence through the verification pipeline.
class Outcome {
  const Outcome({
    required this.verdict,
    required this.confidence,
    required this.reasoning,
    required this.message,
    required this.hash,
    this.missing = const [],
    this.flags = const [],
    this.usedLlm = false,
  });

  final Verdict verdict;
  final double confidence;
  final String reasoning;
  final String message;
  final String hash;
  final List<String> missing;
  final List<String> flags;
  final bool usedLlm;

  bool get passed => verdict == Verdict.pass;
}
