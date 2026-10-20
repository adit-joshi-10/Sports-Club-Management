import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';

/// Success celebration: confetti plus a big "GOAL!". Call Goal.show(...).
class Goal {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GoalOverlay(message: message, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _GoalOverlay extends StatefulWidget {
  const _GoalOverlay({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_GoalOverlay> createState() => _GoalOverlayState();
}

class _GoalOverlayState extends State<_GoalOverlay> {
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 1400));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confetti.play();
    _timer = Timer(const Duration(milliseconds: 2400), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(0, -.35),
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 28,
                maxBlastForce: 28,
                minBlastForce: 8,
                gravity: .22,
                colors: const [Arena.gold, Arena.orange, Arena.pitch, Arena.chalk],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GOAL!',
                    style: ArenaText.display(120, color: Arena.gold, spacing: 6)
                        .copyWith(shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 24),
                    ]),
                  ).animate().scale(
                        begin: const Offset(.4, .4),
                        duration: 450.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    widget.message.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: ArenaText.display(26, spacing: 3).copyWith(
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 150.ms)
                  .then(delay: 1700.ms)
                  .fadeOut(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}