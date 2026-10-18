import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import 'pitch_background.dart';

enum BallKind { football, basketball, cricket, tennis }

/// Draws a sports ball with a CustomPainter (no image assets needed).
class BallPainter extends CustomPainter {
  const BallPainter(this.kind, {this.spin = 0});

  final BallKind kind;
  final double spin; // radians

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));

    canvas.save();
    canvas.rotate(spin);
    switch (kind) {
      case BallKind.football:
        _football(canvas, r);
      case BallKind.basketball:
        _basketball(canvas, r);
      case BallKind.cricket:
        _cricket(canvas, r);
      case BallKind.tennis:
        _tennis(canvas, r);
    }
    canvas.restore();

    // Lighting is drawn un-rotated so the highlight stays put while it spins.
    final shade = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.4, -.5),
        radius: 1.0,
        colors: [Color(0x59FFFFFF), Color(0x00FFFFFF), Color(0x40000000)],
        stops: [0, .5, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, shade);
    canvas.restore();
  }

  Path _pentagon(Offset center, double radius, double rotation) {
    final p = Path();
    for (var i = 0; i < 5; i++) {
      final a = rotation + i * 2 * math.pi / 5;
      final pt = center + Offset(math.cos(a), math.sin(a)) * radius;
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  void _football(Canvas canvas, double r) {
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFF4F6F8));
    final dark = Paint()..color = const Color(0xFF1A2233);
    final seam = Paint()
      ..color = const Color(0xFF1A2233)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .06
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_pentagon(Offset.zero, r * .34, -math.pi / 2), dark);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(dir * (r * .34), dir * (r * .7), seam);
      canvas.drawPath(_pentagon(dir * r, r * .3, a + math.pi), dark);
    }
  }

  void _basketball(Canvas canvas, double r) {
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFE8672B));
    final line = Paint()
      ..color = const Color(0xFF2B1608)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .07;
    canvas.drawLine(Offset(-r, 0), Offset(r, 0), line);
    canvas.drawLine(Offset(0, -r), Offset(0, r), line);
    canvas.drawCircle(Offset(-r * 1.25, 0), r * .95, line);
    canvas.drawCircle(Offset(r * 1.25, 0), r * .95, line);
  }

  void _cricket(Canvas canvas, double r) {
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFB3202A));
    final seam = Paint()
      ..color = const Color(0xFFF2E6C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .05;
    canvas.drawLine(Offset(-r, -r * .06), Offset(r, -r * .06), seam);
    canvas.drawLine(Offset(-r, r * .06), Offset(r, r * .06), seam);
    final stitch = Paint()
      ..color = const Color(0xFFF2E6C9)
      ..strokeWidth = r * .04
      ..strokeCap = StrokeCap.round;
    for (var i = -6; i <= 6; i++) {
      final x = i * r / 6.5;
      canvas.drawLine(Offset(x, -r * .2), Offset(x + r * .08, r * .2), stitch);
    }
  }

  void _tennis(Canvas canvas, double r) {
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFCFE23B));
    final line = Paint()
      ..color = const Color(0xFFF7FBE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .1;
    canvas.drawCircle(Offset(-r * 1.3, 0), r, line);
    canvas.drawCircle(Offset(r * 1.3, 0), r, line);
  }

  @override
  bool shouldRepaint(BallPainter old) => old.kind != kind || old.spin != spin;
}

/// A small continuously spinning ball (button spinners, decoration).
class SpinningBall extends StatelessWidget {
  const SpinningBall({
    super.key,
    this.size = 22,
    this.kind = BallKind.football,
    this.period = const Duration(milliseconds: 800),
  });

  final double size;
  final BallKind kind;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: BallPainter(kind)),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: period);
  }
}

/// The loading indicator: a ball that bounces, squashes on landing and
/// changes sport every bounce. Status text rotates like a stadium announcer.
class BallLoader extends StatefulWidget {
  const BallLoader({
    super.key,
    this.size = 64,
    this.kind,
    this.label,
    this.showLabel = true,
  });

  final double size;
  final BallKind? kind; // null = cycle through all sports
  final String? label; // null = rotating messages
  final bool showLabel;

  @override
  State<BallLoader> createState() => _BallLoaderState();
}

class _BallLoaderState extends State<BallLoader>
    with SingleTickerProviderStateMixin {
  static const _lines = [
    'WARMING UP',
    'LACING BOOTS',
    'CHECKING THE LINEUP',
    'WALKING OUT',
  ];

  late final AnimationController _c;
  int _bounces = 0;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..addListener(_onTick)
      ..repeat();
  }

  void _onTick() {
    if (_c.value < _last) setState(() => _bounces++); // one bounce finished
    _last = _c.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final kind =
        widget.kind ?? BallKind.values[_bounces % BallKind.values.length];
    final label = widget.label ?? _lines[(_bounces ~/ 2) % _lines.length];
    final height = size * 1.1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final lift = 1 - math.pow(2 * t - 1, 2).toDouble(); // gravity arc
            final squash = math.pow(1 - lift, 8).toDouble(); // flatten on impact
            return SizedBox(
              width: size * 1.6,
              height: size + height + size * .25,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: size * (0.9 - .35 * lift),
                      height: size * .12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        color: Colors.black.withValues(alpha: .45 - .25 * lift),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size * .1 + lift * height,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(
                          1 + .14 * squash, 1 - .16 * squash, 1),
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: CustomPaint(
                          painter: BallPainter(kind,
                              spin: (_bounces + t) * math.pi * 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              key: ValueKey(label),
              style: ArenaText.display(20, color: Arena.mist, spacing: 3),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-screen splash/loader on the pitch background.
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: Center(child: BallLoader(size: 72, label: label)),
      ),
    );
  }
}