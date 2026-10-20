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
import 'team_sheet_screen.dart';

const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// Training sessions. Admin manages them, a coach sees their own and opens
/// the team sheet, a member sees sessions of the sports they joined.
/// The server decides what each role receives.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Session> _sessions = const [];
  bool _loading = true;
  String? _error;

  ClubRole get _role => context.read<AuthState>().user!.role;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = false}) async {
    final repo = context.read<ClubRepository>();
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await repo.sessions();
      if (!mounted) return;
      setState(() {
        _sessions = list;
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

  Future<void> _openForm({Session? existing}) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    List<Sport> sports;
    List<Coach> coaches;
    try {
      sports = await repo.sports();
      coaches = await repo.coaches();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    final message = await showDialog<String>(
      context: context,
      builder: (_) => SessionFormDialog(
        existing: existing,
        sports: sports,
        coaches: coaches,
        save: (body) async {
          if (existing == null) {
            await repo.createSession(body);
          } else {
            await repo.updateSession(existing.scheduleId, body);
          }
        },
      ),
    );
    if (message == null || !mounted) return;
    await _load();
    if (mounted) Goal.show(context, message);
  }

  Future<void> _delete(Session s) async {
    final repo = context.read<ClubRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmSubstitution(
      context,
      title: 'CALL OFF SESSION?',
      message:
          'Cancel ${s.sportName} on ${s.sessionDate}? Any attendance already marked for it is deleted too.',
      confirmLabel: 'CALL OFF',
    );
    if (!ok || !mounted) return;
    try {
      await repo.deleteSession(s.scheduleId);
      await _load();
      messenger.showSnackBar(const SnackBar(content: Text('Session called off')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openSheet(Session s) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TeamSheetScreen(session: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    final subtitle = switch (role) {
      ClubRole.admin => 'Plan the fixture list for the whole club.',
      ClubRole.coach => 'Your sessions. Open a team sheet to mark attendance.',
      ClubRole.member => 'Sessions for the sports you have joined.',
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'SESSIONS',
            subtitle: subtitle,
            trailing: role == ClubRole.admin
                ? FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('SCHEDULE A SESSION'),
                  )
                : null,
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
                  onPressed: () => _load(showLoader: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('TRY AGAIN'),
                ),
              ],
            ),
          )
        else if (_sessions.isEmpty)
          SliverToBoxAdapter(
            child: OffsideState(
              title: 'NO FIXTURES',
              message: role == ClubRole.member
                  ? 'No sessions yet. Join a sport under MY SPORTS to see its sessions.'
                  : 'No sessions scheduled.',
            ),
          )
        else
          SliverList.separated(
            itemCount: _sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = _sessions[i];
              return _SessionTile(
                session: s,
                index: i,
                onSheet: role == ClubRole.member ? null : () => _openSheet(s),
                onEdit: role == ClubRole.admin ? () => _openForm(existing: s) : null,
                onDelete: role == ClubRole.admin ? () => _delete(s) : null,
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.index,
    this.onSheet,
    this.onEdit,
    this.onDelete,
  });

  final Session session;
  final int index;
  final VoidCallback? onSheet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final date = DateTime.tryParse(session.sessionDate);
    final today = todayIso();
    final (label, color) = session.sessionDate == today
        ? ('TODAY', accent)
        : session.sessionDate.compareTo(today) > 0
            ? ('UPCOMING', Arena.pitch)
            : ('PAST', Arena.mist);
    final hasActions = onSheet != null || onEdit != null || onDelete != null;

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
            color: label == 'TODAY' ? accent.withValues(alpha: .7) : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Arena.night.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(date == null ? '--' : _months[date.month - 1],
                        style: ArenaText.display(16, color: accent, spacing: 2)),
                    Text(date == null ? '--' : date.day.toString().padLeft(2, '0'),
                        style: ArenaText.digits(40, color: Arena.chalk)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SportEmblem(session.iconKey, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.sportName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArenaText.display(28, spacing: 1.8)),
                    const SizedBox(height: 4),
                    Text(
                      '${hm(session.startTime)} - ${hm(session.endTime)}  ·  ${session.venue}',
                      style: const TextStyle(color: Arena.mist, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text('Coach ${session.coachName}',
                        style: const TextStyle(color: Arena.mist, fontSize: 13)),
                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(session.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Arena.mist, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: ArenaText.display(14, color: color, spacing: 2)),
              ),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (onSheet != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          textStyle: ArenaText.display(18, spacing: 2)),
                      onPressed: onSheet,
                      icon: const Icon(Icons.fact_check_rounded, size: 18),
                      label: const Text('TEAM SHEET'),
                    ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit session',
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Call off session',
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: (40 * (index % 12)).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: .05, curve: Curves.easeOutCubic);
  }
}

TimeOfDay? _parseTime(String t) {
  final p = t.split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Create or edit a session (admin). Server errors show as a red card.
class SessionFormDialog extends StatefulWidget {
  const SessionFormDialog({
    super.key,
    this.existing,
    required this.sports,
    required this.coaches,
    required this.save,
  });

  final Session? existing;
  final List<Sport> sports;
  final List<Coach> coaches;
  final Future<void> Function(Map<String, dynamic> body) save;

  @override
  State<SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<SessionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _venue = TextEditingController(text: widget.existing?.venue);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  final _dateText = TextEditingController();
  final _startText = TextEditingController();
  final _endText = TextEditingController();
  int? _sportId;
  int? _coachId;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _busy = false;
  String? _error;
  int _tick = 0;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _sportId = e.sportId;
      _coachId = e.coachId;
      _date = DateTime.tryParse(e.sessionDate);
      _start = _parseTime(e.startTime);
      _end = _parseTime(e.endTime);
      if (_date != null) _dateText.text = isoDate(_date!);
      if (_start != null) _startText.text = _fmt(_start!);
      if (_end != null) _endText.text = _fmt(_end!);
    }
  }

  @override
  void dispose() {
    _venue.dispose();
    _notes.dispose();
    _dateText.dispose();
    _startText.dispose();
    _endText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
      helpText: 'SESSION DATE',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateText.text = isoDate(picked);
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: start ? 'KICK-OFF TIME' : 'FINAL WHISTLE',
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
          _startText.text = _fmt(picked);
        } else {
          _end = picked;
          _endText.text = _fmt(picked);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end!.hour * 60 + _end!.minute <= _start!.hour * 60 + _start!.minute) {
      setState(() {
        _error = 'The final whistle must come after kick-off.';
        _tick++;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final notes = _notes.text.trim();
    final body = <String, dynamic>{
      'sport_id': _sportId,
      'coach_id': _coachId,
      'session_date': isoDate(_date!),
      'start_time': _fmt(_start!),
      'end_time': _fmt(_end!),
      'venue': _venue.text.trim(),
      'notes': notes.isEmpty ? null : notes,
    };
    try {
      await widget.save(body);
      if (!mounted) return;
      Navigator.pop(context, _editing ? 'Session updated' : 'Session scheduled');
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
      title: Text(_editing ? 'EDIT FIXTURE' : 'SCHEDULE A SESSION',
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
                DropdownButtonFormField<int>(
                  value: _sportId,
                  dropdownColor: Arena.standHi,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: [
                    for (final s in widget.sports)
                      DropdownMenuItem(
                        value: s.sportId,
                        child: Row(
                          children: [
                            SportEmblem(s.iconKey, size: 22),
                            const SizedBox(width: 10),
                            Text(s.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _sportId = v),
                  validator: (v) => v == null ? 'Pick a sport' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _coachId,
                  dropdownColor: Arena.standHi,
                  decoration: const InputDecoration(labelText: 'Coach'),
                  items: [
                    for (final c in widget.coaches)
                      DropdownMenuItem(value: c.coachId, child: Text(c.fullName)),
                  ],
                  onChanged: (v) => setState(() => _coachId = v),
                  validator: (v) => v == null ? 'Pick a coach' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dateText,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Pick a date' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startText,
                        readOnly: true,
                        onTap: () => _pickTime(start: true),
                        decoration: const InputDecoration(
                          labelText: 'Kick-off',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Pick a time' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endText,
                        readOnly: true,
                        onTap: () => _pickTime(start: false),
                        decoration: const InputDecoration(
                          labelText: 'Final whistle',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Pick a time' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _venue,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    prefixIcon: Icon(Icons.stadium_rounded),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.length < 2) return 'At least 2 characters';
                    if (s.length > 100) return 'At most 100 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Coach notes (optional)',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length > 500 ? 'At most 500 characters' : null,
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
              : Text(_editing ? 'SAVE CHANGES' : 'SCHEDULE'),
        ),
      ],
    );
  }
}