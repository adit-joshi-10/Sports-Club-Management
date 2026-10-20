import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/club_repository.dart';
import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../widgets/sport/arena_widgets.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';
import '../../widgets/sport/pitch_background.dart';
import '../../widgets/sport/sport_card.dart';

Color _statusColor(String status) => switch (status) {
      'present' => Arena.pitch,
      'late' => Arena.yellowCard,
      _ => Arena.redCard,
    };

/// Coach's team sheet: tap Present / Late / Absent for each registered player.
/// First tap creates the attendance record, later taps change it.
class TeamSheetScreen extends StatefulWidget {
  const TeamSheetScreen({super.key, required this.session});

  final Session session;

  @override
  State<TeamSheetScreen> createState() => _TeamSheetScreenState();
}

class _TeamSheetScreenState extends State<TeamSheetScreen> {
  List<RosterEntry> _roster = [];
  final Set<int> _busy = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ClubRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await repo.roster(widget.session.scheduleId);
      if (!mounted) return;
      setState(() {
        _roster = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _mark(RosterEntry entry, String status) async {
    if (entry.status == status || _busy.contains(entry.memberId)) return;
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(entry.memberId));
    try {
      final record = entry.attendanceId == null
          ? await repo.markAttendance(
              widget.session.scheduleId, entry.memberId, status)
          : await repo.updateAttendance(entry.attendanceId!, status);
      if (!mounted) return;
      setState(() {
        final i = _roster.indexWhere((e) => e.memberId == entry.memberId);
        if (i >= 0) {
          _roster[i] = RosterEntry(
            memberId: entry.memberId,
            fullName: entry.fullName,
            attendanceId: record.attendanceId,
            status: record.status,
          );
        }
        _busy.remove(entry.memberId);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(entry.memberId));
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final accent = Theme.of(context).colorScheme.primary;
    final marked = _roster.where((e) => e.status != null).length;

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('BACK TO SESSIONS'),
                      ),
                    ),
                    PageHeader(
                      title: 'TEAM SHEET',
                      subtitle:
                          '${s.sportName} · ${s.sessionDate} · ${hm(s.startTime)}-${hm(s.endTime)} · ${s.venue}',
                      trailing: SportEmblem(s.iconKey, size: 56),
                    ),
                    if (!_loading && _error == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Text('$marked / ${_roster.length}',
                                style: ArenaText.digits(34, color: accent)),
                            const SizedBox(width: 10),
                            const Text('PLAYERS MARKED',
                                style: TextStyle(
                                    color: Arena.mist, letterSpacing: 2, fontSize: 12)),
                          ],
                        ),
                      ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: BallLoader(size: 56));
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardBanner(message: _error!),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('TRY AGAIN'),
          ),
        ],
      );
    }
    if (_roster.isEmpty) {
      return const SingleChildScrollView(
        child: OffsideState(
          title: 'NO SQUAD',
          message: 'No players are registered for this sport yet.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: _roster.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = _roster[i];
        final busy = _busy.contains(e.memberId);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Arena.stand.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: e.status == null
                  ? Colors.white12
                  : _statusColor(e.status!).withValues(alpha: .6),
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 14,
            children: [
              SizedBox(
                width: 220,
                child: Text(e.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArenaText.display(26, spacing: 1.6)),
              ),
              for (final st in const ['present', 'late', 'absent'])
                _StatusButton(
                  label: st.toUpperCase(),
                  color: _statusColor(st),
                  selected: e.status == st,
                  enabled: !busy,
                  onTap: () => _mark(e, st),
                ),
              if (busy) const SpinningBall(size: 20),
            ],
          ),
        ).animate(delay: (30 * (i % 12)).ms).fadeIn(duration: 250.ms);
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: selected ? 1 : .5)),
          ),
          child: Text(
            label,
            style: ArenaText.display(18,
                color: selected ? Arena.night : color, spacing: 2),
          ),
        ),
      ),
    );
  }
}