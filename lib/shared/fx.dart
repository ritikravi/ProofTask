import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/storage.dart';

/// True when the user (or OS) asked for less motion.
bool reduceMotionOf(BuildContext context, WidgetRef ref) =>
    ref.watch(settingsProvider.select((s) => s.reduceMotion)) ||
    MediaQuery.of(context).disableAnimations;

// ------------------------------------------------------------- sparkle

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path()..moveTo(c.dx, c.dy - r);
    path.quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy);
    path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r);
    path.quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy);
    path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// 4-point sticker. Decorative: hidden from screen readers.
class Sparkle extends StatelessWidget {
  const Sparkle({
    super.key,
    this.size = 40,
    this.color = AppColors.lime,
    this.angle = 0.2,
  });
  final double size;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      ),
    ),
  );
}

// -------------------------------------------------------------- mascot

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.bg,
    required this.ink,
    required this.skeptical,
  });
  final Color bg;
  final Color ink;
  final bool skeptical;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const teeth = 6;
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.9);
    final step = w / teeth;
    for (var i = 0; i < teeth; i++) {
      final x = w - step * i;
      body.lineTo(x - step / 2, h);
      body.lineTo(x - step, h * 0.9);
    }
    body.close();
    canvas.drawPath(body, Paint()..color = bg);

    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = ink;
    // eyes
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.06, fill);
    canvas.drawCircle(Offset(w * 0.68, h * 0.42), w * 0.06, fill);
    // brows: left flat, right raised when skeptical
    canvas.drawLine(Offset(w * 0.22, h * 0.31), Offset(w * 0.42, h * 0.31), p);
    if (skeptical) {
      canvas.drawLine(Offset(w * 0.58, h * 0.24), Offset(w * 0.78, h * 0.2), p);
    } else {
      canvas.drawLine(
        Offset(w * 0.58, h * 0.31),
        Offset(w * 0.78, h * 0.31),
        p,
      );
    }
    // mouth
    final mouth = Path()
      ..moveTo(w * 0.36, h * 0.66)
      ..quadraticBezierTo(
        w * 0.5,
        skeptical ? h * 0.62 : h * 0.74,
        w * 0.64,
        h * 0.66,
      );
    canvas.drawPath(mouth, p);
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.bg != bg || old.ink != ink || old.skeptical != skeptical;
}

/// The raised-eyebrow receipt. [skeptical] false = grudging approval.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    this.size = 96,
    this.skeptical = true,
    this.paper = Colors.white,
  });
  final double size;
  final bool skeptical;
  final Color paper;

  @override
  Widget build(BuildContext context) => Semantics(
    label: skeptical ? 'Skeptical receipt mascot' : 'Approving receipt mascot',
    child: CustomPaint(
      size: Size(size * 0.8, size),
      painter: _MascotPainter(
        bg: paper,
        ink: AppColors.ink,
        skeptical: skeptical,
      ),
    ),
  );
}

// ------------------------------------------------------------ confetti

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  final _rnd = math.Random(7);
  late final List<_Piece> _pieces = List.generate(70, (_) => _Piece(_rnd));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    ),
  );
}

class _Piece {
  _Piece(math.Random r)
    : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.3,
      speed = 280 + r.nextDouble() * 420,
      spin = (r.nextDouble() - 0.5) * 14,
      size = 6 + r.nextDouble() * 8,
      color = const [
        AppColors.ink,
        Colors.white,
        AppColors.coral,
        AppColors.pink,
        AppColors.surface,
      ][r.nextInt(5)];
  final double angle, speed, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.3);
    for (final p in pieces) {
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + 520 * t * t;
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        Paint()..color = p.color.withValues(alpha: (1 - t).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// --------------------------------------------------------------- shake

/// Horizontal shake once on first build (±6px x3, 300ms).
class ShakeOnce extends StatelessWidget {
  const ShakeOnce({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, t, c) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0),
        child: c,
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------- entrance anim

/// Fade + slide up 12px, 220ms, staggered 40ms per [index].
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });
  final Widget child;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final delay = (index.clamp(0, 10)) * 40;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delay),
      curve: Interval(delay / (220 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------- zigzag

class ZigZagRibbon extends StatelessWidget {
  const ZigZagRibbon({super.key, required this.color, this.height = 18});
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(double.infinity, height),
      painter: _ZigZagPainter(color),
    ),
  );
}

class _ZigZagPainter extends CustomPainter {
  _ZigZagPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    final step = size.height * 1.4;
    var x = 0.0;
    var up = true;
    while (x < size.width + step) {
      x += step;
      path.lineTo(x, up ? 0 : size.height);
      up = !up;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ZigZagPainter old) => old.color != color;
}
