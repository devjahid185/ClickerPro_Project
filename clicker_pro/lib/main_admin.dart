// lib/main_admin.dart
//
// Separate Dart entry point for the PRO ADMIN Android build flavor. Skips
// the studio app entirely — Firebase, the Drift DB, the outbox worker, and
// every studio screen (splash/onboarding/bookings/dashboard) never load.
// This build is a thin client for the platform admin API only.
//
// IMPORTANT — the Flutter Gradle plugin has NO automatic per-flavor Dart
// entrypoint selection. `--flavor proAdmin` alone still compiles the normal
// `lib/main.dart`. This file is only used when the `-t` / `--target` flag
// is passed explicitly:
//
//   flutter build apk --flavor proAdmin --release -t lib/main_admin.dart
//
// Building `--flavor proAdmin` WITHOUT `-t lib/main_admin.dart` silently
// produces the full studio app under the PRO ADMIN app name/icon — this is
// the exact bug that shipped once already. Always pass the target flag for
// this flavor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/admin/presentation/admin_home_screen.dart';
import 'features/admin/presentation/admin_login_screen.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/domain/user_role.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not bundled or unreadable; AppConfig falls back to safe defaults.
  }

  runApp(const ProviderScope(child: ProAdminApp()));
}

class ProAdminApp extends StatelessWidget {
  const ProAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.active = ActivePalette.clickerPro;
    return MaterialApp(
      title: 'Graphy7 — Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clickerPro(),
      home: const _AdminRoot(),
    );
  }
}

/// Restores any cached admin session before deciding between the login
/// screen and the home screen — mirrors the studio app's splash-restore
/// step but without the brand animation (this is an internal tool, not a
/// customer-facing first impression).
class _AdminRoot extends ConsumerStatefulWidget {
  const _AdminRoot();

  @override
  ConsumerState<_AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends ConsumerState<_AdminRoot> {
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionControllerProvider);

    return sessionAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.voidBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      ),
      error: (_, _) => const AdminLoginScreen(),
      data: (session) {
        if (session != null && session.user.role == UserRole.webAdmin) {
          return const AdminHomeScreen();
        }
        return const AdminLoginScreen();
      },
    );
  }
}
