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

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');

/// Admin-only coaching staff. Search runs on the server.
class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  List<Coach> _coaches = const [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _requestId = 0;

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
      final list = await repo.coaches(search: _query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _coaches = list;
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

  Future<void> _openForm({Coach? existing}) async {
    final repo = context.read<ClubRepository>();
    final message = await showDialog<String>(
      context: context,
      builder: (_) => CoachFormDialog(
        existing: existing,
        save: (body) async {
          if (existing == null) {
            await repo.createCoach(body);
          } else {
            await repo.updateCoach(existing.coachId, body);
          }
        },
      ),
    );
    if (message == null || !mounted) return;
    await _load();
    if (mounted) Goal.show(context, message);
  }

  Future<void> _delete(Coach c) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmSubstitution(
      context,
      message:
          'Release ${c.fullName} from the coaching staff? Their login is deleted too. A coach with training sessions cannot be released.',
      confirmLabel: 'RELEASE',
    );
    if (!ok || !mounted) return;
    try {
      await repo.deleteCoach(c.coachId);
      await _load();
      messenger.showSnackBar(SnackBar(content: Text('${c.fullName} released')));
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
            title: 'COACHES',
            subtitle: _loading
                ? 'Loading the staff list...'
                : '${_coaches.length} on the coaching staff',
            trailing: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('SIGN A COACH'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ScoutSearchBar(
            hint: 'Scout a coach by name, sport or email...',
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
        else if (_coaches.isEmpty)
          SliverToBoxAdapter(
            child: OffsideState(
              message: _query.trim().isEmpty
                  ? 'No coaches on the staff yet.'
                  : 'No coaches match "${_query.trim()}".',
            ),
          )
        else
          SliverList.separated(
            itemCount: _coaches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CoachTile(
              coach: _coaches[i],
              index: i,
              onEdit: () => _openForm(existing: _coaches[i]),
              onDelete: () => _delete(_coaches[i]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.coach,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Coach coach;
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: .16),
              border: Border.all(color: accent.withValues(alpha: .6), width: 2),
            ),
            child: Icon(Icons.sports_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coach.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArenaText.display(28, spacing: 1.8)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (coach.specialization != null)
                      _Meta(Icons.military_tech_rounded, coach.specialization!),
                    _Meta(Icons.alternate_email_rounded, coach.email),
                    if (coach.phone != null) _Meta(Icons.phone_rounded, coach.phone!),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit ${coach.fullName}',
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Release ${coach.fullName}',
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

/// Sign a new coach (login + profile) or edit one. Server errors show as a
/// red card without closing the dialog. Pops a success message, or null.
class CoachFormDialog extends StatefulWidget {
  const CoachFormDialog({super.key, this.existing, required this.save});

  final Coach? existing;
  final Future<void> Function(Map<String, dynamic> body) save;

  @override
  State<CoachFormDialog> createState() => _CoachFormDialogState();
}

class _CoachFormDialogState extends State<CoachFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _name = TextEditingController(text: widget.existing?.fullName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _spec = TextEditingController(text: widget.existing?.specialization);
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _tick = 0;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    _spec.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final spec = _spec.text.trim();
    final body = <String, dynamic>{
      'full_name': name,
      'phone': phone.isEmpty ? null : phone,
      'specialization': spec.isEmpty ? null : spec,
      if (!_editing) 'email': _email.text.trim(),
      if (!_editing) 'password': _password.text,
    };
    try {
      await widget.save(body);
      if (!mounted) return;
      Navigator.pop(context, _editing ? '$name updated' : '$name joins the staff');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
        _tick++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Arena.stand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Text(_editing ? 'EDIT COACH CARD' : 'SIGN A NEW COACH',
          style: ArenaText.display(32, spacing: 2)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  CardBanner(key: ValueKey(_tick), message: _error!),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.length < 2) return 'At least 2 characters';
                    if (s.length > 120) return 'At most 120 characters';
                    return null;
                  },
                ),
                if (!_editing) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Login email'),
                    validator: (v) => _emailRe.hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Enter a valid email',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Temporary password',
                      helperText: '8 to 72 characters',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      final s = v ?? '';
                      if (s.length < 8) return 'At least 8 characters';
                      if (s.length > 72) return 'At most 72 characters';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _spec,
                  decoration: const InputDecoration(
                      labelText: 'Specialization (optional)'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null;
                    if (s.length < 2) return 'At least 2 characters';
                    if (s.length > 100) return 'At most 100 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    helperText: '7 to 15 digits, optional leading +',
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null;
                    return _phoneRe.hasMatch(s) ? null : 'Digits only, 7 to 15 long';
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinningBall(size: 18),
                    SizedBox(width: 10),
                    Text('SAVING...'),
                  ],
                )
              : Text(_editing ? 'SAVE CHANGES' : 'SIGN COACH'),
        ),
      ],
    );
  }
}