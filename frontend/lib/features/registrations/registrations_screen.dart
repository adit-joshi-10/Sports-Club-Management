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
import '../../widgets/sport/goal_burst.dart';
import '../../widgets/sport/sport_card.dart';

/// Member: join or leave sports. Admin: overview of every sign-up.
class RegistrationsScreen extends StatelessWidget {
  const RegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthState>().user!.role;
    return role == ClubRole.member
        ? const _MemberSportsView()
        : const _AdminSignupsView();
  }
}

class _MemberSportsView extends StatefulWidget {
  const _MemberSportsView();

  @override
  State<_MemberSportsView> createState() => _MemberSportsViewState();
}

class _MemberSportsViewState extends State<_MemberSportsView> {
  List<Sport> _sports = const [];
  Map<int, int> _joined = {}; // sportId -> registrationId
  final Set<int> _busy = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    final repo = context.read<ClubRepository>();
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final sports = await repo.sports();
      final mine = await repo.myRegistrations();
      if (!mounted) return;
      setState(() {
        _sports = sports;
        _joined = {for (final r in mine) r.sportId: r.registrationId};
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _join(Sport s) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(s.sportId));
    try {
      await repo.register(s.sportId);
      await _load(silent: true);
      if (mounted) Goal.show(context, 'You joined ${s.name}');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(s.sportId));
    }
  }

  Future<void> _leave(Sport s) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final id = _joined[s.sportId];
    if (id == null) return;
    final ok = await confirmSubstitution(
      context,
      title: 'LEAVE THE SQUAD?',
      message: 'Leave ${s.name}? You will stop seeing its sessions.',
      confirmLabel: 'LEAVE',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(s.sportId));
    try {
      await repo.cancelRegistration(id);
      await _load(silent: true);
      messenger.showSnackBar(SnackBar(content: Text('You left ${s.name}')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(s.sportId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'MY SPORTS',
            subtitle: _loading
                ? 'Loading the club sports...'
                : 'You are on ${_joined.length} of ${_sports.length} squads.',
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
        else if (_sports.isEmpty)
          const SliverToBoxAdapter(
            child: OffsideState(message: 'The club has no sports yet.'),
          )
        else
          SliverList.separated(
            itemCount: _sports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = _sports[i];
              final joined = _joined.containsKey(s.sportId);
              final busy = _busy.contains(s.sportId);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Arena.standHi, Arena.stand],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: joined ? accent.withValues(alpha: .7) : Colors.white12),
                ),
                child: Row(
                  children: [
                    SportEmblem(s.iconKey, size: 52),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name.toUpperCase(),
                              style: ArenaText.display(28, spacing: 1.8)),
                          Text(s.description ?? 'No scouting report yet.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Arena.mist, fontSize: 13, height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (busy)
                      const SpinningBall(size: 26)
                    else if (joined)
                      OutlinedButton.icon(
                        onPressed: () => _leave(s),
                        icon: Icon(Icons.check_circle_rounded, size: 18, color: accent),
                        label: const Text('ON THE SQUAD'),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            textStyle: ArenaText.display(18, spacing: 2)),
                        onPressed: () => _join(s),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('JOIN'),
                      ),
                  ],
                ),
              ).animate(delay: (50 * (i % 10)).ms).fadeIn(duration: 300.ms).slideY(begin: .05);
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _AdminSignupsView extends StatefulWidget {
  const _AdminSignupsView();

  @override
  State<_AdminSignupsView> createState() => _AdminSignupsViewState();
}

class _AdminSignupsViewState extends State<_AdminSignupsView> {
  List<Registration> _regs = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final list = await repo.allRegistrations();
      if (!mounted) return;
      setState(() {
        _regs = list;
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

  List<Registration> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _regs;
    return _regs
        .where((r) =>
            r.memberName.toLowerCase().contains(q) ||
            r.sportName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final list = _filtered;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'SIGN-UPS',
            subtitle: _loading
                ? 'Loading registrations...'
                : '${_regs.length} players signed up across the club.',
          ),
        ),
        SliverToBoxAdapter(
          child: ScoutSearchBar(
            hint: 'Scout by player or sport...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
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
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: OffsideState(
              message: _regs.isEmpty
                  ? 'Nobody has signed up yet.'
                  : 'Nothing matches "$_query".',
            ),
          )
        else
          SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Arena.stand.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind_rounded, color: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(r.memberName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArenaText.display(24, spacing: 1.6)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r.sportName.toUpperCase(),
                          style: ArenaText.display(16, color: accent, spacing: 2)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      r.registeredAt.length >= 10 ? r.registeredAt.substring(0, 10) : r.registeredAt,
                      style: const TextStyle(color: Arena.mist, fontSize: 12),
                    ),
                  ],
                ),
              ).animate(delay: (30 * (i % 12)).ms).fadeIn(duration: 250.ms);
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}