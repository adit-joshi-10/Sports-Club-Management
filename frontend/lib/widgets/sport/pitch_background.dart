import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/arena_colors.dart';

/// Stadium-at-night backdrop: mown-grass stripes, faint pitch markings and
/// two floodlight beams that sway slowly.
class PitchBackground extends StatefulWidget {
  const PitchBackground({super.key, required this.child});
  final Widget child;

  @override
  State<PitchBackground> createState() => _PitchBackgroundState();
}

class _PitchBackgroundState extends State<PitchBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 14))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _PitchPainter(_c.value)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Night sky into the pitch
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Arena.night, Color(0xFF0A2438)],
        ).createShader(rect),
    );

    // Mown-grass stripes
    final stripe = size.width / 12;
    final grass = Paint()..color = Arena.pitch.withValues(alpha: .035);
    for (var i = 0; i < 12; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * stripe, 0, stripe, size.height), grass);
    }

    // Pitch markings
    final line = Paint()
      ..color = Arena.chalk.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final field = Rect.fromLTWH(size.width * .04, size.height * .07,
        size.width * .92, size.height * .86);
    canvas.drawRect(field, line);
    canvas.drawLine(Offset(field.center.dx, field.top),
        Offset(field.center.dx, field.bottom), line);
    canvas.drawCircle(field.center, field.height * .17, line);
    canvas.drawCircle(field.center, 4, Paint()..color = line.color);
    final boxH = field.height * .46;
    final boxW = field.width * .13;
    final smallH = boxH * .45;
    final smallW = boxW * .42;
    canvas.drawRect(
        Rect.fromLTWH(field.left, field.center.dy - boxH / 2, boxW, boxH), line);
    canvas.drawRect(
        Rect.fromLTWH(
            field.right - boxW, field.center.dy - boxH / 2, boxW, boxH),
        line);
    canvas.drawRect(
        Rect.fromLTWH(
            field.left, field.center.dy - smallH / 2, smallW, smallH),
        line);
    canvas.drawRect(
        Rect.fromLTWH(
            field.right - smallW, field.center.dy - smallH / 2, smallW, smallH),
        line);

    // Swaying floodlight beams
    for (var i = 0; i < 2; i++) {
      final sway = math.sin((t + i * .5) * 2 * math.pi) * size.width * .05;
      final originX = i == 0 ? size.width * .12 : size.width * .88;
      final targetX = (i == 0 ? size.width * .38 : size.width * .62) + sway;
      final spread = size.width * .2;
      final beam = Path()
        ..moveTo(originX - 10, -10)
        ..lineTo(originX + 10, -10)
        ..lineTo(targetX + spread, size.height)
        ..lineTo(targetX - spread, size.height)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Arena.chalk.withValues(alpha: .13),
              Arena.chalk.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    // Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.1,
          colors: [Colors.transparent, Color(0x66000000)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.t != t;
}