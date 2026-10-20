import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/club_repository.dart';
import '../../models/app_user.dart';
import '../../models/club_models.dart';
import '../../theme/role_style.dart';
import '../../widgets/sport/arena_widgets.dart';
import '../../widgets/sport/jersey_card.dart';
import '../../widgets/sport/scoreboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: user.role.zone,
            subtitle: 'Welcome, ${user.displayName}',
          ),
          switch (user.role) {
            ClubRole.admin => const _AdminBoard(),
            ClubRole.coach => const _CoachBoard(),
            ClubRole.member => const _MemberBoard(),
          },
        ],
      ),
    );
  }
}

class _AdminBoard extends StatelessWidget {
  const _AdminBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return FutureSection<List<int>>(
      load: () async => [
        (await repo.members()).length,
        (await repo.coaches()).length,
        (await repo.sports()).length,
        (await repo.sessions()).length,
        (await repo.allRegistrations()).length,
      ],
      builder: (context, c) => Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          ScoreboardCard(label: 'PLAYERS', value: c[0], icon: Icons.groups_rounded),
          ScoreboardCard(label: 'COACHES', value: c[1], icon: Icons.sports_rounded),
          ScoreboardCard(label: 'SPORTS', value: c[2], icon: Icons.sports_soccer_rounded),
          ScoreboardCard(label: 'SESSIONS', value: c[3], icon: Icons.event_rounded),
          ScoreboardCard(label: 'SIGN-UPS', value: c[4], icon: Icons.assignment_ind_rounded),
        ],
      ),
    );
  }
}

class _CoachBoard extends StatelessWidget {
  const _CoachBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return FutureSection<List<int>>(
      load: () async {
        final sessions = await repo.sessions();
        final marks = await repo.attendance();
        final today = todayIso();
        return [
          sessions.length,
          sessions.where((s) => s.sessionDate == today).length,
          marks.length,
        ];
      },
      builder: (context, c) => Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          ScoreboardCard(label: 'MY SESSIONS', value: c[0], icon: Icons.event_rounded),
          ScoreboardCard(label: 'TODAY', value: c[1], icon: Icons.today_rounded),
          ScoreboardCard(label: 'MARKS MADE', value: c[2], icon: Icons.fact_check_rounded),
        ],
      ),
    );
  }
}

class _MemberBoard extends StatelessWidget {
  const _MemberBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return FutureSection<(Member, List<int>)>(
      load: () async {
        final me = await repo.myProfile();
        final regs = await repo.myRegistrations();
        final sessions = await repo.sessions();
        final att = await repo.myAttendance();
        return (
          me,
          [
            regs.length,
            sessions.length,
            att.where((a) => a.status != 'absent').length,
          ],
        );
      },
      builder: (context, data) {
        final c = data.$2;
        return Wrap(
          spacing: 28,
          runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            JerseyCard(name: data.$1.fullName, number: data.$1.memberId),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ScoreboardCard(
                    label: 'MY SPORTS', value: c[0], icon: Icons.how_to_reg_rounded),
                ScoreboardCard(
                    label: 'MY SESSIONS', value: c[1], icon: Icons.event_rounded),
                ScoreboardCard(
                    label: 'ATTENDED', value: c[2], icon: Icons.check_circle_rounded),
              ],
            ),
          ],
        );
      },
    );
  }
}