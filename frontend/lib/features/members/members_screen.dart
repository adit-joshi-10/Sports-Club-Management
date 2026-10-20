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
import '../../widgets/sport/goal_burst.dart';
import 'member_form_dialog.dart';

/// Admin-only roster. Search runs on the server (GET /members?search=).
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<Member> _members = const [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _requestId = 0; // ignore out-of-order responses while typing

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = false}) async {
    final repo = context.read<ClubRepository>();
    final id = ++_requestId;
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await repo.members(search: _query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _members = list;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Member? existing}) async {
    final repo = context.read<ClubRepository>();
    final message = await showDialog<String>(
      context: context,
      builder: (_) => MemberFormDialog(
        existing: existing,
        save: (body) async {
          if (existing == null) {
            await repo.createMember(body);
          } else {
            await repo.updateMember(existing.memberId, body);
          }
        },
      ),
    );
    if (message == null || !mounted) return;
    await _load();
    if (mounted) Goal.show(context, message);
  }

  Future<void> _delete(Member m) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmSubstitution(
      context,
      message:
          'Release ${m.fullName} from the club? Their login, sport registrations and attendance records are deleted too. This cannot be undone.',
      confirmLabel: 'RELEASE',
    );
    if (!ok || !mounted) return;
    try {
      await repo.deleteMember(m.memberId);
      await _load();
      messenger.showSnackBar(SnackBar(content: Text('${m.fullName} released')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'PLAYERS',
            subtitle: _loading
                ? 'Loading the squad sheet...'
                : '${_members.length} on the squad sheet',
            trailing: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('SIGN A PLAYER'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ScoutSearchBar(
            hint: 'Scout a player by name or email...',
            debounce: const Duration(milliseconds: 350),
            onChanged: (v) {
              _query = v;
              _load();
            },
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
                  onPressed: () => _load(showLoader: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('TRY AGAIN'),
                ),
              ],
            ),
          )
        else if (_members.isEmpty)
          SliverToBoxAdapter(
            child: OffsideState(
              message: _query.trim().isEmpty
                  ? 'No players on the squad sheet yet.'
                  : 'No players match "${_query.trim()}".',
            ),
          )
        else
          SliverList.separated(
            itemCount: _members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PlayerTile(
              member: _members[i],
              index: i,
              onEdit: () => _openForm(existing: _members[i]),
              onDelete: () => _delete(_members[i]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.member,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Member member;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Arena.standHi, Arena.stand],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: .16),
              border: Border.all(color: accent.withValues(alpha: .6), width: 2),
            ),
            child: Text('${member.memberId}',
                style: ArenaText.digits(30, color: accent)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArenaText.display(28, spacing: 1.8)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _Meta(Icons.alternate_email_rounded, member.email),
                    if (member.phone != null)
                      _Meta(Icons.phone_rounded, member.phone!),
                    _Meta(Icons.event_rounded, 'Joined ${member.joinedOn}'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit ${member.fullName}',
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Release ${member.fullName}',
            icon: const Icon(Icons.person_remove_rounded, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    )
        .animate(delay: (40 * (index % 12)).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: .03, curve: Curves.easeOutCubic);
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Arena.mist),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Arena.mist, fontSize: 13)),
        ),
      ],
    );
  }
}