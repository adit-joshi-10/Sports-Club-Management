import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';

/// Stadium scoreboard: digits count up when the card appears.
class ScoreboardCard extends StatelessWidget {
  const ScoreboardCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.width = 250,
  });

  final String label;
  final int value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E2240), Arena.night],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: .35)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .12), blurRadius: 24),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Arena.mist),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: ArenaText.display(18, color: Arena.mist, spacing: 2.4)),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Arena.redCard, shape: BoxShape.circle),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: .25, end: 1, duration: 700.ms),
                const SizedBox(width: 5),
                const Text('LIVE',
                    style: TextStyle(
                        color: Arena.mist, fontSize: 9, letterSpacing: 1.6)),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                v.toString().padLeft(2, '0'),
                style: ArenaText.digits(84, color: accent),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0)]),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .12, curve: Curves.easeOutCubic);
  }
}