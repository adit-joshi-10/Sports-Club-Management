import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/api_client.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import 'ball_loader.dart';
import 'card_banner.dart';

/// Poster-style page title with an accent underline.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ArenaText.display(58, spacing: 2.5)),
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Arena.mist, fontSize: 15, height: 1.4)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: .1, curve: Curves.easeOutCubic);
  }
}

/// Empty state: a waving offside flag.
class OffsideState extends StatelessWidget {
  const OffsideState({super.key, required this.message, this.title = 'OFFSIDE!'});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 56, color: accent)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -.04, end: .04, duration: 800.ms, curve: Curves.easeInOut),
            const SizedBox(height: 10),
            Text(title, style: ArenaText.display(44, spacing: 3)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Arena.mist)),
          ],
        ),
      ),
    );
  }
}

/// Honest list of modules that are not connected to the backend yet.
class BenchCard extends StatelessWidget {
  const BenchCard({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Arena.stand.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_seat_rounded, color: Arena.mist),
              const SizedBox(width: 10),
              Text('ON THE BENCH', style: ArenaText.display(24, spacing: 2.5)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'These modules are not connected yet. They join the squad in later milestones.',
            style: TextStyle(color: Arena.mist, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(
                  avatar: const Icon(Icons.hourglass_top_rounded,
                      size: 16, color: Arena.mist),
                  label: Text(item),
                  backgroundColor: Arena.night.withValues(alpha: .6),
                  side: const BorderSide(color: Colors.white12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loads something once: ball loader while waiting, red card + retry on error.
class FutureSection<T> extends StatefulWidget {
  const FutureSection({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<FutureSection<T>> createState() => _FutureSectionState<T>();
}

class _FutureSectionState<T> extends State<FutureSection<T>> {
  late Future<T> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: BallLoader(size: 52)),
          );
        }
        if (snap.hasError) {
          final err = snap.error;
          final message =
              err is ApiException ? err.message : 'Something went wrong.';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardBanner(message: message),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('TRY AGAIN'),
              ),
            ],
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

/// Search field with a whistle icon, a focus glow and optional debounce
/// (use a debounce when each change triggers a server request).
class ScoutSearchBar extends StatefulWidget {
  const ScoutSearchBar({
    super.key,
    required this.onChanged,
    this.hint = 'Scout...',
    this.debounce = Duration.zero,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;

  @override
  State<ScoutSearchBar> createState() => _ScoutSearchBarState();
}

class _ScoutSearchBarState extends State<ScoutSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    if (widget.debounce == Duration.zero) {
      widget.onChanged(value);
    } else {
      _timer = Timer(widget.debounce, () => widget.onChanged(value));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focus.hasFocus
              ? [BoxShadow(color: accent.withValues(alpha: .25), blurRadius: 18)]
              : const [],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _changed,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.sports),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      _changed('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// "Substitution?" confirmation, used before any destructive action.
Future<bool> confirmSubstitution(
  BuildContext context, {
  required String message,
  String title = 'SUBSTITUTION?',
  String confirmLabel = 'CONFIRM',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Arena.stand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Arena.yellowCard),
          const SizedBox(width: 10),
          Text(title, style: ArenaText.display(30, spacing: 2)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(message,
            style: const TextStyle(color: Arena.mist, height: 1.45)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('KEEP ON FIELD'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Arena.redCard,
            foregroundColor: Arena.chalk,
            minimumSize: const Size(0, 46),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}