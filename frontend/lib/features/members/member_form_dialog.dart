import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phoneRe = RegExp(r'^\+?[0-9]{7,15}$');

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Sign a new player (login + profile) or edit an existing one.
/// The API call happens inside, so server errors (duplicate email...) show
/// as a red card without closing the dialog. Pops a success message, or null.
class MemberFormDialog extends StatefulWidget {
  const MemberFormDialog({super.key, this.existing, required this.save});

  final Member? existing;
  final Future<void> Function(Map<String, dynamic> body) save;

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController();
  late final _password = TextEditingController();
  late final _name = TextEditingController(text: widget.existing?.fullName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  final _dobText = TextEditingController();
  DateTime? _dob;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _tick = 0;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final raw = widget.existing?.dateOfBirth;
    if (raw != null) {
      _dob = DateTime.tryParse(raw);
      if (_dob != null) _dobText.text = _iso(_dob!);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    _dobText.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'DATE OF BIRTH',
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobText.text = _iso(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final body = <String, dynamic>{
      'full_name': name,
      'phone': phone.isEmpty ? null : phone,
      'date_of_birth': _dob == null ? null : _iso(_dob!),
      if (!_editing) 'email': _email.text.trim(),
      if (!_editing) 'password': _password.text,
    };
    try {
      await widget.save(body);
      if (!mounted) return;
      Navigator.pop(context, _editing ? '$name updated' : '$name joins the squad');
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
      title: Text(_editing ? 'EDIT PLAYER CARD' : 'SIGN A NEW PLAYER',
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dobText,
                  readOnly: true,
                  onTap: _pickDob,
                  decoration: InputDecoration(
                    labelText: 'Date of birth (optional)',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: _dob == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _dob = null;
                              _dobText.clear();
                            }),
                          ),
                  ),
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
              : Text(_editing ? 'SAVE CHANGES' : 'SIGN PLAYER'),
        ),
      ],
    );
  }
}