import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../core/url_guard.dart';
import '../verification/commit_fetcher.dart';
import '../verification/verification_service.dart';

class SubmitProofScreen extends ConsumerStatefulWidget {
  const SubmitProofScreen({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends ConsumerState<SubmitProofScreen> {
  final _text = TextEditingController();
  final _url = TextEditingController();
  final _commit = TextEditingController();
  EvidenceType _type = EvidenceType.text;
  Uint8List? _image;
  String _imageName = '';
  String _imageMime = 'image/jpeg';
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    _url.dispose();
    _commit.dispose();
    super.dispose();
  }

  String? get _urlError {
    final v = _url.text.trim();
    if (v.isEmpty) return null;
    final u = Uri.tryParse(v);
    return (u == null || !isSafePublicUrl(u)) ? 'Needs a public http(s) link.' : null;
  }

  String? get _commitError {
    final v = _commit.text.trim();
    if (v.isEmpty) return null;
    return parseCommitUrl(v) == null ? 'Use a github.com/…/commit/… or …/pull/… link.' : null;
  }

  bool get _ready {
    if (_busy) return false;
    return switch (_type) {
      EvidenceType.text => _text.text.trim().length >= minEvidenceChars,
      EvidenceType.url => _url.text.trim().isNotEmpty && _urlError == null,
      EvidenceType.commit => _commit.text.trim().isNotEmpty && _commitError == null,
      EvidenceType.screenshot => _image != null,
    };
  }

  Evidence _evidence() => switch (_type) {
    EvidenceType.text => Evidence(_type, _text.text.trim()),
    EvidenceType.url => Evidence(_type, _url.text.trim()),
    EvidenceType.commit => Evidence(_type, _commit.text.trim()),
    EvidenceType.screenshot => Evidence(_type, _imageName, bytes: _image, mime: _imageMime),
  };

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1568,
        maxHeight: 1568,
        imageQuality: 80,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _image = bytes;
        _imageName = f.name.isEmpty ? 'screenshot' : f.name;
        _imageMime = f.mimeType ?? 'image/jpeg';
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open that image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final tasks = ref.read(tasksProvider);
    final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null || task.isLocked || task.isDone) return;
    setState(() => _busy = true);
    final service = ref.read(verificationServiceProvider);
    final accepted = {
      for (final t in tasks)
        for (final a in t.attempts)
          if (a.type == EvidenceType.screenshot && a.verdict == Verdict.pass) a.hash,
    };
    final evidence = _evidence();
    final outcome = await service.submit(task, evidence, acceptedImageHashes: accepted);
    if (!mounted) return;
    ref.read(tasksProvider.notifier).recordAttempt(task.id, evidence, outcome);
    context.pushReplacement('/task/${task.id}/verdict', extra: outcome);
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(settingsProvider).hasKey;
    final charCount = _text.text.trim().length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Submit Your Proof',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _busy
          ? const _Verifying()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Subtitle
                Text(
                  'Show evidence that you\'ve completed this task.\nThe AI will verify your submission.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Evidence type selector
                Row(
                  children: [
                    _TypeButton(
                      label: 'Text',
                      selected: _type == EvidenceType.text,
                      onTap: () => setState(() => _type = EvidenceType.text),
                    ),
                    const SizedBox(width: 8),
                    _TypeButton(
                      label: 'Screenshot',
                      selected: _type == EvidenceType.screenshot,
                      onTap: () => setState(() => _type = EvidenceType.screenshot),
                    ),
                    const SizedBox(width: 8),
                    _TypeButton(
                      label: 'URL',
                      selected: _type == EvidenceType.url,
                      onTap: () => setState(() => _type = EvidenceType.url),
                    ),
                    const SizedBox(width: 8),
                    _TypeButton(
                      label: 'Commit',
                      selected: _type == EvidenceType.commit,
                      onTap: () => setState(() => _type = EvidenceType.commit),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Input area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _buildInputArea(charCount),
                ),

                const SizedBox(height: 20),

                // Tips card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tips for good proof:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TipItem(text: 'Be specific and detailed'),
                      _TipItem(text: 'Include relevant context'),
                      _TipItem(text: 'Mention key outcomes'),
                      _TipItem(text: 'The more details, the better!'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _ready ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.outline,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Submit for Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInputArea(int charCount) {
    switch (_type) {
      case EvidenceType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _text,
              minLines: 6,
              maxLines: 10,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Describe what you did in detail...\n(e.g. what you built, what you learned, key insights, etc.)',
                hintStyle: TextStyle(color: AppColors.ink.withOpacity(0.4)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$charCount/1000',
                style: TextStyle(
                  color: AppColors.ink.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case EvidenceType.url:
        return TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'https://example.com/your-work',
            hintStyle: TextStyle(color: AppColors.ink.withOpacity(0.4)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorText: _urlError,
          ),
        );
      case EvidenceType.commit:
        return TextField(
          controller: _commit,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'https://github.com/user/repo/commit/...',
            hintStyle: TextStyle(color: AppColors.ink.withOpacity(0.4)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorText: _commitError,
          ),
        );
      case EvidenceType.screenshot:
        return Column(
          children: [
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_rounded, size: 20),
                    label: Text(_image == null ? 'Choose Image' : 'Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.surface, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.surface, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
    }
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.surface : AppColors.outline,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.ink.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.ink.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Verifying extends StatelessWidget {
  const _Verifying();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.surface,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Verifying your proof...',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is checking your submission',
            style: TextStyle(
              color: AppColors.ink.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
