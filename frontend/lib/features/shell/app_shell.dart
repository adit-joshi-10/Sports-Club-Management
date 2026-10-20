import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../models/app_user.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../theme/role_style.dart';
import '../../widgets/sport/pitch_background.dart';
import '../dashboard/dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../coaches/coaches_screen.dart';
import '../members/members_screen.dart';
import '../registrations/registrations_screen.dart';
import '../schedule/sessions_screen.dart';
import '../sports/sports_screen.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget Function() page;
}

/// The signed-in frame: sidebar on wide screens, bottom bar on narrow ones.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Only modules that exist on the backend. Members is admin-only.
    List<_Dest> _destinations(ClubRole role) {
    final dash = _Dest('DASHBOARD', Icons.dashboard_rounded, () => const DashboardScreen());
    final sports = _Dest('SPORTS', Icons.sports_soccer_rounded, () => const SportsScreen());
    final sessions = _Dest('SESSIONS', Icons.event_rounded, () => const SessionsScreen());
    final attendance =
        _Dest('ATTENDANCE', Icons.fact_check_rounded, () => const AttendanceScreen());
    return switch (role) {
      ClubRole.admin => [
          dash,
          _Dest('PLAYERS', Icons.groups_rounded, () => const MembersScreen()),
          _Dest('COACHES', Icons.sports_rounded, () => const CoachesScreen()),
          sports,
          sessions,
          _Dest('SIGN-UPS', Icons.assignment_ind_rounded, () => const RegistrationsScreen()),
          attendance,
        ],
      ClubRole.coach => [dash, sessions, attendance, sports],
      ClubRole.member => [
          dash,
          sports,
          _Dest('MY SPORTS', Icons.how_to_reg_rounded, () => const RegistrationsScreen()),
          sessions,
          attendance,
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) return const SizedBox.shrink(); // mid sign-out
    final dests = _destinations(user.role);
    final index = _index.clamp(0, dests.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final page = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(index), child: dests[index].page()),
    );

    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: Arena.stand,
              indicatorColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .25),
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in dests)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
      body: PitchBackground(
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    _Sidebar(
                      user: user,
                      dests: dests,
                      index: index,
                      onSelect: (i) => setState(() => _index = i),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 28, 32, 0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _TopBar(user: user),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                        child: page,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Arena.gold, Color(0xFFB88A00)],
            ),
          ),
          child: const Icon(Icons.sports_soccer_rounded,
              color: Arena.night, size: 22),
        ),
        const SizedBox(width: 10),
        Text('SCMS', style: ArenaText.display(28, spacing: 3)),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.role});
  final ClubRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: role.accent.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 16, color: role.accent),
          const SizedBox(width: 6),
          Text(role.zone,
              style: ArenaText.display(15, color: role.accent, spacing: 2.2)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 4),
      child: Row(
        children: [
          const _BrandMark(),
          const Spacer(),
          _ZoneChip(role: user.role),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.dests,
    required this.index,
    required this.onSelect,
  });

  final AppUser user;
  final List<_Dest> dests;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = user.role.accent;
    return Container(
      width: 256,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Arena.stand.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 18),
          _ZoneChip(role: user.role),
          const SizedBox(height: 24),
          for (var i = 0; i < dests.length; i++)
            _NavTile(
              label: dests[i].label,
              icon: dests[i].icon,
              active: i == index,
              accent: accent,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(user.role.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(user.role.tag,
                        style: const TextStyle(
                            color: Arena.mist, fontSize: 11, letterSpacing: 1.6)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthState>().logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('SIGN OUT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: .16) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? accent.withValues(alpha: .5) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: active ? accent : Arena.mist),
              const SizedBox(width: 12),
              Text(label,
                  style: ArenaText.display(22,
                      color: active ? Arena.chalk : Arena.mist, spacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}