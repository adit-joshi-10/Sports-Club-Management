import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/club_repository.dart';
import '../../models/app_user.dart';
import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
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
          _body(user.role),
        ],
      ),
    );
  }

  Widget _body(ClubRole role) => switch (role) {
        ClubRole.admin => const _AdminBoard(),
        ClubRole.coach => const _CoachBoard(),
        ClubRole.member => const _MemberBoard(),
      };
}

class _AdminBoard extends StatelessWidget {
  const _AdminBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureSection<(int, int)>(
          load: () async {
            final sports = await repo.sports();
            final members = await repo.memberCount();
            return (members, sports.length);
          },
          builder: (context, data) => Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              ScoreboardCard(
                  label: 'MEMBERS', value: data.$1, icon: Icons.groups_rounded),
              ScoreboardCard(
                  label: 'SPORTS',
                  value: data.$2,
                  icon: Icons.sports_soccer_rounded),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const BenchCard(items: [
          'Coach management',
          'Training schedules',
          'Registrations overview',
          'Attendance overview',
        ]),
      ],
    );
  }
}

class _CoachBoard extends StatelessWidget {
  const _CoachBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureSection<int>(
          load: () async => (await repo.sports()).length,
          builder: (context, count) => ScoreboardCard(
            label: 'SPORTS IN THE CLUB',
            value: count,
            icon: Icons.sports_soccer_rounded,
          ),
        ),
        const SizedBox(height: 28),
        const BenchCard(items: [
          'My training schedules',
          'Team sheet and attendance marking',
          'Attendance history',
        ]),
      ],
    );
  }
}

class _MemberBoard extends StatelessWidget {
  const _MemberBoard();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClubRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureSection<(Member, int)>(
          load: () async {
            final me = await repo.myProfile();
            final sports = await repo.sports();
            return (me, sports.length);
          },
          builder: (context, data) => Wrap(
            spacing: 28,
            runSpacing: 24,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              JerseyCard(name: data.$1.fullName, number: data.$1.memberId),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScoreboardCard(
                    label: 'SPORTS AVAILABLE',
                    value: data.$2,
                    icon: Icons.sports_soccer_rounded,
                  ),
                  const SizedBox(height: 16),
                  _InfoTile(label: 'MEMBER SINCE', value: data.$1.joinedOn),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const BenchCard(items: [
          'Register for a sport',
          'My training schedule',
          'My attendance',
        ]),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Arena.stand.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArenaText.display(16, color: Arena.mist, spacing: 2.4)),
          const SizedBox(height: 4),
          Text(value, style: ArenaText.digits(30, color: Arena.chalk)),
        ],
      ),
    );
  }
}