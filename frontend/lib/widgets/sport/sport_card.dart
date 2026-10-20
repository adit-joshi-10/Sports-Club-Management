import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import 'ball_loader.dart';

/// Icon keys the backend stores in sports.icon_key.
const sportIconKeys = [
  'football',
  'cricket',
  'basketball',
  'tennis',
  'badminton',
  'swimming',
  'generic',
];

/// Balls are drawn by BallPainter; other sports use Material icons.
class SportEmblem extends StatelessWidget {
  const SportEmblem(this.iconKey, {super.key, this.size = 72});

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final kind = switch (iconKey) {
      'football' => BallKind.football,
      'cricket' => BallKind.cricket,
      'basketball' => BallKind.basketball,
      'tennis' => BallKind.tennis,
      _ => null,
    };
    if (kind != null) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: BallPainter(kind)),
      );
    }
    final icon = switch (iconKey) {
      'badminton' => Icons.sports_tennis_rounded,
      'swimming' => Icons.pool_rounded,
      _ => Icons.sports_rounded,
    };
    return Icon(icon, size: size * .9, color: Theme.of(context).colorScheme.primary);
  }
}

/// Collectible trading card for one sport. Lifts on hover.
class SportCard extends StatefulWidget {
  const SportCard({
    super.key,
    required this.sport,
    this.index = 0,
    this.onEdit,
    this.onDelete,
  });

  final Sport sport;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<SportCard> createState() => _SportCardState();
}

class _SportCardState extends State<SportCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final sport = widget.sport;
    final hasActions = widget.onEdit != null || widget.onDelete != null;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -8 : 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Arena.standHi, Arena.stand],
          ),
          border: Border.all(
              color: _hover ? accent : Colors.white12, width: _hover ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: (_hover ? accent : Colors.black)
                  .withValues(alpha: _hover ? .28 : .3),
              blurRadius: _hover ? 28 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Text('No. ${sport.sportId.toString().padLeft(2, '0')}',
                      style: ArenaText.digits(22, color: accent)),
                  const Spacer(),
                  if (hasActions) ...[
                    if (widget.onEdit != null)
                      IconButton(
                        tooltip: 'Edit ${sport.name}',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: widget.onEdit,
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: 'Remove ${sport.name}',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        onPressed: widget.onDelete,
                      ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          accent.withValues(alpha: .28),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    SportEmblem(sport.iconKey),
                  ],
                ),
              ),
            ),
            Text(sport.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArenaText.display(32, spacing: 2)),
            const SizedBox(height: 4),
            Text(
              sport.description ?? 'No scouting report yet.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Arena.mist, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0)]),
              ),
            ),
          ],
        ),
      ),
    );

    return card
        .animate(delay: (60 * (widget.index % 12)).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: .08, curve: Curves.easeOutCubic);
  }
}