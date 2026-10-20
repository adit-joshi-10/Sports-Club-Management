import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_state.dart';
import '../../core/club_repository.dart';
import '../../models/app_user.dart';
import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../widgets/sport/arena_widgets.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';
import '../../widgets/sport/scoreboard_card.dart';

Color _statusColor(String status) => switch (status) {
      'present' => Arena.pitch,
      'late' => Arena.yellowCard,
      _ => Arena.redCard,
    };

/// Member: own attendance only (server enforced). Coach: their own sessions.
/// Admin: everything.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _records = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  bool get _isMember => context.read<AuthState>().user!.role == ClubRole.member;

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
      final list = _isMember ? await repo.myAttendance() : await repo.attendance();
      if (!mounted) return;
      setState(() {
        _records = list;
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

  List<AttendanceRecord> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records
        .where((r) =>
            r.memberName.toLowerCase().contains(q) ||
            r.sportName.toLowerCase().contains(q) ||
            r.status.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final member = _isMember;
    final list = _filtered;
    final attended = _records.where((r) => r.status != 'absent').length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'ATTENDANCE',
            subtitle: member
                ? 'Your training record, session by session.'
                : 'Marked attendance across the sessions you can see.',
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: BallLoader(size: 56)),
            ),
          )
        else if (_error != null)
          SliverToBoxAdapter(
            child: Column(
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
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ScoreboardCard(
                  label: member ? 'SESSIONS ATTENDED' : 'ATTENDED',
                  value: attended,
                  icon: Icons.check_circle_rounded,
                ),
                ScoreboardCard(
                  label: 'RECORDS',
                  value: _records.length,
                  icon: Icons.fact_check_rounded,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          if (!member)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ScoutSearchBar(
                  hint: 'Scout by player, sport or status...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: OffsideState(
                title: 'NO RECORDS',
                message: _records.isEmpty
                    ? 'No attendance has been marked yet.'
                    : 'Nothing matches "$_query".',
              ),
            )
          else
            SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _RecordTile(record: list[i], showPlayer: !member, index: i),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.showPlayer,
    required this.index,
  });

  final AttendanceRecord record;
  final bool showPlayer;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Arena.stand.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showPlayer
                      ? record.memberName.toUpperCase()
                      : record.sportName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArenaText.display(26, spacing: 1.6),
                ),
                const SizedBox(height: 2),
                Text(
                  showPlayer
                      ? '${record.sportName} · ${record.sessionDate}'
                      : record.sessionDate,
                  style: const TextStyle(color: Arena.mist, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(record.status.toUpperCase(),
                style: ArenaText.display(16, color: color, spacing: 2)),
          ),
        ],
      ),
    ).animate(delay: (30 * (index % 12)).ms).fadeIn(duration: 250.ms);
  }
}