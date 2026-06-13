import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/providers.dart';
import 'features/bookings/application/booking_providers.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/settings/application/language_controller.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';

class ClickerProApp extends ConsumerWidget {
  const ClickerProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(activeLocaleProvider);
    final themeMode = ref.watch(resolvedThemeModeProvider);
    // Flip the AppColors palette (custom-painted surfaces read this flag)
    // to match the resolved theme. `system` follows the device brightness.
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    AppColors.isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);
    return MaterialApp(
      title: 'Clicker Pro',
      debugShowCheckedModeBanner: false,
      // Light = Orange Horizon Pro · Dark = Deep Ocean. The Settings
      // toggle drives `themeMode`.
      theme: AppTheme.orangeHorizon(),
      darkTheme: AppTheme.oceanDeep(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Splash drives the initial routing decision (onboarding / login /
      // dashboard). `onGenerateRoute` is wired so any `pushNamed` call
      // throughout the app resolves through the central route table.
      home: const _OutboxAutoStart(child: SplashScreen()),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

/// Boots the bookings module's outbox worker once the connectivity
/// stream is available. Wraps the splash screen so the worker is alive
/// from the very first frame; it stays attached to the provider
/// container's lifetime via `outboxWorkerProvider.onDispose`.
class _OutboxAutoStart extends ConsumerStatefulWidget {
  const _OutboxAutoStart({required this.child});
  final Widget child;

  @override
  ConsumerState<_OutboxAutoStart> createState() => _OutboxAutoStartState();
}

class _OutboxAutoStartState extends ConsumerState<_OutboxAutoStart> {
  bool _started = false;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      final worker = ref.read(outboxWorkerProvider);
      worker.start(_connectivityController.stream);
    });
  }

  @override
  void dispose() {
    _connectivityController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Forward every connectivity emission to the worker via our
    // controller. `ref.listen` keeps the listener wired across
    // Riverpod's normal lifecycle without re-triggering `start`.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      next.whenData((online) {
        if (!_connectivityController.isClosed) {
          _connectivityController.add(online);
        }
      });
    });
    return widget.child;
  }
}
