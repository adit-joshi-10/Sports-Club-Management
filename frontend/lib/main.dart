import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_state.dart';
import 'core/club_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'models/app_user.dart';
import 'theme/arena_colors.dart';
import 'theme/arena_theme.dart';
import 'theme/role_style.dart';
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
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<ClubRepository>(
          create: (ctx) => ClubRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AuthState>(
          create: (ctx) => AuthState(ctx.read<ApiClient>())..restore(),
        ),
      ],
      child: const _ArenaApp(),
    );
  }
}

/// Sits below the providers so the whole theme can follow the signed-in role.
class _ArenaApp extends StatelessWidget {
  const _ArenaApp();

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthState, ClubRole?>((a) => a.user?.role);
    return MaterialApp(
      title: 'SCMS | Sports Club',
      debugShowCheckedModeBanner: false,
      theme: ArenaTheme.build(role?.accent ?? Arena.orange),
      home: const _Root(),
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
      AuthStatus.signedIn => const AppShell(key: ValueKey('shell')),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: screen,
    );
  }
}