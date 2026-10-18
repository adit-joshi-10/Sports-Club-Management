import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'theme/arena_colors.dart';
import 'theme/arena_theme.dart';
import 'widgets/sport/ball_loader.dart';
import 'widgets/sport/pitch_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScmsApp());
}

class ScmsApp extends StatelessWidget {
  const ScmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthState>(
          create: (ctx) => AuthState(ctx.read<ApiClient>())..restore(),
        ),
      ],
      child: MaterialApp(
        title: 'SCMS | Sports Club',
        debugShowCheckedModeBanner: false,
        theme: ArenaTheme.build(Arena.orange),
        home: const _Root(),
      ),
    );
  }
}

/// Chooses the screen from the session state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthState, AuthStatus>((a) => a.status);
    final Widget screen = switch (status) {
      AuthStatus.unknown => const FullScreenLoader(key: ValueKey('boot')),
      AuthStatus.signedOut => const LoginScreen(key: ValueKey('login')),
      AuthStatus.signedIn => const _SignedInStub(key: ValueKey('in')),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: screen,
    );
  }
}

/// Temporary: proves the real login worked. Replaced in stage 5b.
class _SignedInStub extends StatelessWidget {
  const _SignedInStub({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user!;
    return Scaffold(
      body: PitchBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('KICK-OFF!', style: ArenaText.display(84, spacing: 3)),
              const SizedBox(height: 8),
              Text(user.displayName,
                  style: const TextStyle(fontSize: 20, color: Arena.chalk)),
              Text('role: ${user.role.name}',
                  style: const TextStyle(color: Arena.mist)),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () => context.read<AuthState>().logout(),
                  child: const Text('SIGN OUT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}