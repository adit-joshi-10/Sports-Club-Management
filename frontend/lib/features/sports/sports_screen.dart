import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_state.dart';
import '../../core/club_repository.dart';
import '../../models/app_user.dart';
import '../../models/club_models.dart';
import '../../widgets/sport/arena_widgets.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';
import '../../widgets/sport/goal_burst.dart';
import '../../widgets/sport/sport_card.dart';
import 'sport_form_dialog.dart';

class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  List<Sport> _sports = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  bool get _isAdmin =>
      context.read<AuthState>().user?.role == ClubRole.admin;

  @override
  void initState() {
    super.initState();
    _load(silent: true);
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
      final list = await repo.sports();
      if (!mounted) return;
      setState(() {
        _sports = list;
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

  List<Sport> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sports;
    return _sports
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openForm({Sport? existing}) async {
    final repo = context.read<ClubRepository>();
    final message = await showDialog<String>(
      context: context,
      builder: (_) => SportFormDialog(
        existing: existing,
        save: (body) async {
          if (existing == null) {
            await repo.createSport(body);
          } else {
            await repo.updateSport(existing.sportId, body);
          }
        },
      ),
    );
    if (message == null || !mounted) return;
    await _load(silent: true);
    if (mounted) Goal.show(context, message);
  }

  Future<void> _delete(Sport sport) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmSubstitution(
      context,
      message: 'Take ${sport.name} off the club roster? This cannot be undone.',
      confirmLabel: 'REMOVE',
    );
    if (!ok || !mounted) return;
    try {
      await repo.deleteSport(sport.sportId);
      await _load(silent: true);
      messenger.showSnackBar(SnackBar(content: Text('${sport.name} removed')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _isAdmin;
    final list = _filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'SPORTS',
            subtitle: admin
                ? 'Sign new sports, update the roster, retire old ones.'
                : 'Every sport the club runs.',
            trailing: admin
                ? FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('SIGN A SPORT'),
                  )
                : null,
          ),
        ),
        SliverToBoxAdapter(
          child: ScoutSearchBar(
            hint: 'Scout a sport...',
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
              message: _sports.isEmpty
                  ? 'No sports on the roster yet.'
                  : 'Nothing matches "$_query".',
            ),
          )
        else
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 340,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) => SportCard(
              sport: list[i],
              index: i,
              onEdit: admin ? () => _openForm(existing: list[i]) : null,
              onDelete: admin ? () => _delete(list[i]) : null,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}