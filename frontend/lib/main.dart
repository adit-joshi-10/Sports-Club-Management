
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_state.dart';
import 'core/club_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'theme/arena_colors.dart';
import 'theme/arena_theme.dart';
import 'widgets/sport/ball_loader.dart';

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
        // Shared API client
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        // Repository used by dashboard and sports screens
        Provider<ClubRepository>(
          create: (ctx) => ClubRepository(
            ctx.read<ApiClient>(),
          ),
        ),

        // Authentication state
        ChangeNotifierProvider<AuthState>(
          create: (ctx) => AuthState(
            ctx.read<ApiClient>(),
          )..restore(),
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

/// Chooses the screen according to the authentication state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthState, AuthStatus>(
      (auth) => auth.status,
    );

    final Widget screen = switch (status) {
      AuthStatus.unknown => const FullScreenLoader(
          key: ValueKey('boot'),
        ),
      AuthStatus.signedOut => const LoginScreen(
          key: ValueKey('login'),
        ),
      AuthStatus.signedIn => const AppShell(
          key: ValueKey('app-shell'),
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: screen,
    );
  }
}
