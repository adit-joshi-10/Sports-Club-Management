import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/club_models.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';
import '../../widgets/sport/sport_card.dart';

/// Create or edit a sport. The API call happens inside, so a server error
/// (for example a duplicate name) shows as a red card without closing the dialog.
/// Pops with a success message, or null if cancelled.
class SportFormDialog extends StatefulWidget {
  const SportFormDialog({super.key, this.existing, required this.save});

  final Sport? existing;
  final Future<void> Function(Map<String, dynamic> body) save;

  @override
  State<SportFormDialog> createState() => _SportFormDialogState();
}

class _SportFormDialogState extends State<SportFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late String _icon = sportIconKeys.contains(widget.existing?.iconKey)
      ? widget.existing!.iconKey
      : (widget.existing == null ? 'football' : 'generic');
  bool _busy = false;
  String? _error;
  int _tick = 0;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _name.text.trim();
    final desc = _desc.text.trim();
    try {
      await widget.save({
        'name': name,
        'description': desc.isEmpty ? null : desc,
        'icon_key': _icon,
      });
      if (!mounted) return;
      Navigator.pop(
        context,
        widget.existing == null ? '$name signed to the club' : '$name lineup updated',
      );
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
    final editing = widget.existing != null;
    return AlertDialog(
      backgroundColor: Arena.stand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Text(editing ? 'EDIT TEAM SHEET' : 'SIGN A NEW SPORT',
          style: ArenaText.display(32, spacing: 2)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                  decoration: const InputDecoration(labelText: 'Sport name'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.length < 2) return 'At least 2 characters';
                    if (s.length > 80) return 'At most 80 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Scouting report (optional)',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length > 500 ? 'At most 500 characters' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _icon,
                  dropdownColor: Arena.standHi,
                  decoration: const InputDecoration(labelText: 'Emblem'),
                  items: [
                    for (final key in sportIconKeys)
                      DropdownMenuItem(
                        value: key,
                        child: Row(
                          children: [
                            SportEmblem(key, size: 24),
                            const SizedBox(width: 12),
                            Text(key[0].toUpperCase() + key.substring(1)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _icon = v ?? _icon),
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
              : Text(editing ? 'SAVE CHANGES' : 'SIGN SPORT'),
        ),
      ],
    );
  }
}