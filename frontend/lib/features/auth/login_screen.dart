import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../theme/arena_colors.dart';
import '../../theme/arena_theme.dart';
import '../../widgets/sport/ball_loader.dart';
import '../../widgets/sport/card_banner.dart';
import '../../widgets/sport/pitch_background.dart';

/// Demo-only quick-fill chips (fictional seed accounts for the live demo).
/// Set to false for anything that is not a classroom demo.
const bool kShowDemoLogins = true;

class _DemoLogin {
  const _DemoLogin(this.label, this.icon, this.email, this.password);
  final String label;
  final IconData icon;
  final String email;
  final String password;
}

const _demoLogins = [
  _DemoLogin('Admin', Icons.shield_rounded, 'admin@scms.demo', 'Admin@123'),
  _DemoLogin('Coach', Icons.sports_rounded, 'vikram.rathore@scms.demo',
      'Coach@123'),
  _DemoLogin('Player', Icons.person_rounded, 'aarav.sharma@scms.demo',
      'Member@123'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  int _errorTick = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error =
        await context.read<AuthState>().login(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
        _errorTick++;
      });
    }
    // On success AuthState switches the screen, so nothing else to do here.
  }

  void _fill(_DemoLogin d) {
    _email.text = d.email;
    _password.text = d.password;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.select<AuthState, String?>((a) => a.notice);
    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : 20, vertical: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1080 : 460),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(child: _hero(true)),
                              const SizedBox(width: 56),
                              SizedBox(width: 420, child: _sheet(notice)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _hero(false),
                              const SizedBox(height: 28),
                              _sheet(notice),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hero(bool wide) {
    final primary = Theme.of(context).colorScheme.primary;
    final big = wide ? 112.0 : 62.0;
    return Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Brand(),
        SizedBox(height: wide ? 48 : 24),
        Text('ENTER', style: ArenaText.display(big, spacing: 3))
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: .25, curve: Curves.easeOutCubic),
        Text('THE ARENA',
                style: ArenaText.display(big, color: primary, spacing: 3))
            .animate(delay: 120.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: .25, curve: Curves.easeOutCubic),
        SizedBox(height: wide ? 20 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Training, squads and attendance, all in one club.',
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: const TextStyle(color: Arena.mist, fontSize: 16, height: 1.5),
          ),
        ).animate(delay: 260.ms).fadeIn(duration: 450.ms),
        SizedBox(height: wide ? 36 : 22),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 22,
          runSpacing: 14,
          children: const [
            _BallTag(BallKind.football, 'FOOTBALL'),
            _BallTag(BallKind.cricket, 'CRICKET'),
            _BallTag(BallKind.basketball, 'BASKETBALL'),
            _BallTag(BallKind.tennis, 'TENNIS'),
          ],
        ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _sheet(String? notice) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Arena.stand.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('TEAM SHEET',
                    style: ArenaText.display(14, color: primary, spacing: 2.4)),
              ),
            ),
            const SizedBox(height: 14),
            Text('SIGN IN', style: ArenaText.display(44, spacing: 2)),
            const SizedBox(height: 4),
            const Text('Use your club credentials to take the field.',
                style: TextStyle(color: Arena.mist)),
            const SizedBox(height: 22),
            if (notice != null) ...[
              CardBanner(message: notice, kind: CardKind.yellow),
              const SizedBox(height: 14),
            ],
            if (_error != null) ...[
              CardBanner(key: ValueKey(_errorTick), message: _error!),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Enter your email';
                if (!s.contains('@')) return "That doesn't look like an email";
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinningBall(size: 22),
                        SizedBox(width: 12),
                        Text('WALKING OUT...'),
                      ],
                    )
                  : const Text('KICK OFF'),
            ),
            if (kShowDemoLogins) ...[
              const SizedBox(height: 22),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Text('DEMO LINEUP',
                  style: ArenaText.display(14, color: Arena.mist, spacing: 2.4)),
              const SizedBox(height: 4),
              const Text('Tap a role to fill fictional demo credentials.',
                  style: TextStyle(color: Arena.mist, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _demoLogins)
                    ActionChip(
                      avatar: Icon(d.icon, size: 16, color: primary),
                      label: Text(d.label),
                      onPressed: _loading ? null : () => _fill(d),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: .08);
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Arena.gold, Color(0xFFB88A00)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Arena.gold.withValues(alpha: .35), blurRadius: 18),
            ],
          ),
          child: const Icon(Icons.sports_soccer_rounded, color: Arena.night),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCMS', style: ArenaText.display(30, spacing: 3)),
            const Text(
              'SPORTS CLUB MANAGEMENT',
              style:
                  TextStyle(color: Arena.mist, fontSize: 10, letterSpacing: 2.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _BallTag extends StatelessWidget {
  const _BallTag(this.kind, this.label);
  final BallKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinningBall(
            size: 38, kind: kind, period: const Duration(seconds: 7)),
        const SizedBox(height: 8),
        Text(label,
            style: ArenaText.display(13, color: Arena.mist, spacing: 2)),
      ],
    );
  }
}