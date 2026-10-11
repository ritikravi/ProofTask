import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/storage.dart';
import '../../shared/widgets.dart';
import '../verification/verification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _grokKey = TextEditingController(
    text: ref.read(settingsProvider).grokKey,
  );
  late final _key = TextEditingController(
    text: ref.read(settingsProvider).apiKey,
  );
  late final _gh = TextEditingController(
    text: ref.read(settingsProvider).githubToken,
  );
  late final _backendUrl = TextEditingController(
    text: ref.read(settingsProvider).backendUrl,
  );
  bool _hideGrok = true;
  bool _hide = true;

  @override
  void dispose() {
    _grokKey.dispose();
    _key.dispose();
    _gh.dispose();
    _backendUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grok API key (recommended)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your xAI Grok key — get one at console.x.ai. Kept on-device, sent only to api.x.ai. Grok is used when set.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _grokKey,
                      obscureText: _hideGrok,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (v) => n.update(s.copyWith(grokKey: v)),
                      decoration: InputDecoration(
                        hintText: 'xai-…',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hideGrok
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _hideGrok = !_hideGrok),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anthropic API key (fallback)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Used only when no Grok key is set. Sent only to api.anthropic.com.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _key,
                      obscureText: _hide,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (v) => n.update(s.copyWith(apiKey: v)),
                      decoration: InputDecoration(
                        hintText: 'sk-ant-…',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GitHub token (optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Only for private repos or to avoid rate limits. Sent only to api.github.com.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _gh,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (v) => n.update(s.copyWith(githubToken: v)),
                      decoration: const InputDecoration(hintText: 'ghp_…'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend mode (optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use your own ProofTask backend server instead of client-side verification. API keys stay server-side.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Use backend API',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: s.useBackend,
                          onChanged: (v) =>
                              n.update(s.copyWith(useBackend: v)),
                        ),
                      ],
                    ),
                    if (s.useBackend) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _backendUrl,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (v) =>
                            n.update(s.copyWith(backendUrl: v)),
                        decoration: const InputDecoration(
                          hintText: 'http://localhost:5000',
                          labelText: 'Backend URL',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Roast intensity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < roastLevels.length; i++)
                          _DarkChip(
                            label: roastLevels[i],
                            selected: s.roastLevel == i,
                            onTap: () => n.update(s.copyWith(roastLevel: i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Not today (supportive tone)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: s.notToday,
                          onChanged: (v) => n.update(s.copyWith(notToday: v)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Reduce motion (no confetti or shake)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: s.reduceMotion,
                          onChanged: (v) =>
                              n.update(s.copyWith(reduceMotion: v)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Strictness',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          [
                            'Lenient',
                            'Normal',
                            'Strict',
                            'Ruthless',
                          ][s.strictness],
                          style: const TextStyle(
                            color: AppColors.lime,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.strictness.toDouble(),
                      min: 0,
                      max: 3,
                      divisions: 3,
                      onChanged: (v) =>
                          n.update(s.copyWith(strictness: v.round())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const BentoCard(
                color: AppColors.surfaceDarkest,
                child: Text(
                  'Honest note: a determined user can still fake proof. Receipts is a friction-and-reflection tool, not forensics.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip for use on dark cards (selected = lime, else outlined white).
class _DarkChip extends StatelessWidget {
  const _DarkChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: selected
                ? null
                : Border.all(color: AppColors.outline, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
