import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';

/// A shirt with the player's surname and squad number (their member id).
class JerseyCard extends StatelessWidget {
  const JerseyCard({super.key, required this.name, required this.number});

  final String name;
  final int number;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final surname = name.trim().split(' ').last.toUpperCase();
    return SizedBox(
      width: 240,
      height: 270,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _JerseyPainter(accent)),
          ),
          Positioned.fill(
            top: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(surname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArenaText.display(26, spacing: 3)),
                Text('$number',
                    style: ArenaText.digits(110, color: Arena.chalk)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: .1, curve: Curves.easeOutCubic);
  }
}

class _JerseyPainter extends CustomPainter {
  _JerseyPainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .28, 0)
      ..quadraticBezierTo(w * .5, h * .16, w * .72, 0)
      ..lineTo(w * .95, h * .10)
      ..lineTo(w, h * .30)
      ..lineTo(w * .82, h * .36)
      ..lineTo(w * .82, h)
      ..lineTo(w * .18, h)
      ..lineTo(w * .18, h * .36)
      ..lineTo(0, h * .30)
      ..lineTo(w * .05, h * .10)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Arena.night, .6)!],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Arena.chalk.withValues(alpha: .3),
    );

    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = Arena.chalk.withValues(alpha: .85);
    canvas.drawPath(
      Path()
        ..moveTo(w * .28, 0)
        ..quadraticBezierTo(w * .5, h * .16, w * .72, 0),
      trim,
    );
    final sleeve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = Arena.chalk.withValues(alpha: .85);
    canvas.drawLine(Offset(w * .02, h * .24), Offset(w * .87, h * .335), sleeve);
    canvas.drawLine(Offset(w * .98, h * .24), Offset(w * .13, h * .335), sleeve);
  }

  @override
  bool shouldRepaint(_JerseyPainter old) => old.accent != accent;
}