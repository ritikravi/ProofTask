import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/models.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.card,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.white10,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.lime,
    this.foreground = AppColors.ink,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: color.withValues(alpha: 0.35),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: selected
                ? null
                : Border.all(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background = AppColors.surfaceDeep,
    this.foreground = Colors.white,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: foreground, size: 22),
          ),
        ),
      ),
    );
  }
}

extension VerdictStyle on Verdict {
  Color get bg => switch (this) {
    Verdict.pass => AppColors.lime,
    Verdict.weak => AppColors.amber,
    Verdict.fail => AppColors.coral,
    Verdict.inconclusive => AppColors.muted,
  };
  Color get fg => this == Verdict.fail ? Colors.white : AppColors.ink;
  IconData get icon => switch (this) {
    Verdict.pass => Icons.check_rounded,
    Verdict.weak => Icons.priority_high_rounded,
    Verdict.fail => Icons.close_rounded,
    Verdict.inconclusive => Icons.help_outline_rounded,
  };
  String get label => switch (this) {
    Verdict.pass => 'Pass',
    Verdict.weak => 'Weak',
    Verdict.fail => 'Fail',
    Verdict.inconclusive => 'Unclear',
  };
}

/// Verdict is never color-only: icon + label always shown.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge(this.verdict, {super.key, this.confidence});
  final Verdict verdict;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    final pct = confidence == null ? '' : ' · ${(confidence! * 100).round()}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verdict.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verdict.icon, size: 16, color: verdict.fg),
          const SizedBox(width: 4),
          Text(
            '${verdict.label}$pct',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: verdict.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class RoastBubble extends StatelessWidget {
  const RoastBubble(this.text, {super.key, this.praise = false});
  final String text;
  final bool praise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: praise ? Colors.white : AppColors.coralLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

String mmss(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
