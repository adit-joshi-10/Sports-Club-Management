import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/arena_colors.dart';

enum CardKind { red, yellow }

/// Inline message styled as a referee card. Red shakes on arrival.
class CardBanner extends StatelessWidget {
  const CardBanner({super.key, required this.message, this.kind = CardKind.red});

  final String message;
  final CardKind kind;

  @override
  Widget build(BuildContext context) {
    final color = kind == CardKind.red ? Arena.redCard : Arena.yellowCard;
    final banner = Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .5)),
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: -.12,
              child: Container(
                width: 20,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Arena.chalk, height: 1.35)),
            ),
          ],
        ),
      ),
    );

    final animated = banner.animate().fadeIn(duration: 200.ms);
    return kind == CardKind.red
        ? animated.shake(hz: 4, duration: 450.ms)
        : animated;
  }
}