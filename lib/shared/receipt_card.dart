import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme.dart';
import '../core/models.dart';
import 'fx.dart';
import 'widgets.dart';

/// Shareable "receipt" for one attempt.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.taskTitle,
    required this.verdict,
    required this.confidence,
    required this.message,
    required this.when,
  });

  final String taskTitle;
  final Verdict verdict;
  final double confidence;
  final String message;
  final DateTime when;

  static String text(String taskTitle, Verdict v, double c, String message) =>
      'RECEIPT — $taskTitle\n${v.label.toUpperCase()} · ${(c * 100).round()}%\n"$message"\n— Receipts';

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      fontFamily: 'monospace',
      color: AppColors.ink,
      fontSize: 14,
      height: 1.4,
    );
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Mascot(
                size: 44,
                skeptical: verdict != Verdict.pass,
                paper: AppColors.canvas,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'RECEIPTS',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ZigZagRibbon(color: AppColors.ink, height: 10),
          const SizedBox(height: 12),
          Text('TASK', style: mono.copyWith(fontSize: 11)),
          Text(taskTitle, style: mono.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('VERDICT', style: mono.copyWith(fontSize: 11)),
          Row(children: [VerdictBadge(verdict, confidence: confidence)]),
          const SizedBox(height: 12),
          Text('"$message"', style: mono),
          const SizedBox(height: 12),
          const ZigZagRibbon(color: AppColors.ink, height: 10),
          const SizedBox(height: 8),
          Text(
            '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}  ·  no refunds',
            style: mono.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Dialog showing the receipt with a Share button (image, else text/clipboard).
Future<void> showReceiptDialog(
  BuildContext context, {
  required String taskTitle,
  required Verdict verdict,
  required double confidence,
  required String message,
  required DateTime when,
}) {
  final key = GlobalKey();
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surfaceDarkest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: ReceiptCard(
                    taskTitle: taskTitle,
                    verdict: verdict,
                    confidence: confidence,
                    message: message,
                    when: when,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Share receipt',
              icon: Icons.ios_share_rounded,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final summary = ReceiptCard.text(
                  taskTitle,
                  verdict,
                  confidence,
                  message,
                );
                try {
                  final bytes = await _capture(key);
                  await Share.shareXFiles(
                    [
                      XFile.fromData(
                        bytes,
                        mimeType: 'image/png',
                        name: 'receipt.png',
                      ),
                    ],
                    text: summary,
                  );
                } on Object {
                  await Clipboard.setData(ClipboardData(text: summary));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sharing unavailable here. Receipt text copied.',
                      ),
                    ),
                  );
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<Uint8List> _capture(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
