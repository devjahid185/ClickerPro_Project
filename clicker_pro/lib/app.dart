import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/providers.dart';
import 'features/bookings/application/booking_providers.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/settings/application/language_controller.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/web_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_colors_pulse.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'theme/reduce_motion.dart';

class ClickerProApp extends ConsumerWidget {
  const ClickerProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(activeLocaleProvider);
    final themeMode = ref.watch(resolvedThemeModeProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final activeAppTheme = ref.watch(themeModeControllerProvider).maybeWhen(
      data: (m) => m,
      orElse: () => AppThemeMode.sunsetStudio,
    );

    // Sync AppColors.isDark so every custom-painted surface reads the
    // correct palette without needing a BuildContext.
    final isDark = activeAppTheme == AppThemeMode.sunrisePulse;
    AppColors.isDark = isDark;
    AppColorsPulse; // ensure the palette class is loaded

    return MaterialApp(
      title: 'Clicker Pro',
      debugShowCheckedModeBanner: false,
      // Sunset Studio = light ThemeData · Sunrise Pulse = dark ThemeData.
      // On web the Scaffold is made transparent so the WebShell's orange
      // glass backdrop shows through; mobile keeps its solid surface.
      theme: kIsWeb
          ? AppTheme.sunsetStudio().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            )
          : AppTheme.sunsetStudio(),
      darkTheme: kIsWeb
          ? AppTheme.sunrisePulse().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            )
          : AppTheme.sunrisePulse(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Key the routed subtree on the active theme so custom-painted widgets
      // (which read AppColors.isDark directly) rebuild on every theme switch.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || reduceMotion,
            // Force 24-hour time everywhere (pickers + Material time rendering)
            // regardless of the device's 12h/24h locale setting.
            alwaysUse24HourFormat: true,
          ),
          child: KeyedSubtree(
            key: ValueKey(isDark ? 'pulse' : 'sunset'),
            // Web-only glassmorphism shell; a pure pass-through on mobile.
            child: WebShell(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      // On web, the initial URL path (e.g. `/book/<token>` shared by a studio)
      // must be honoured instead of always booting the splash flow. Using
      // `onGenerateInitialRoutes` lets that initial path flow through the
      // router; the normal `/` entry still lands on the splash, which then
      // decides onboarding / login / dashboard as before.
      onGenerateInitialRoutes: (initialRoute) {
        if (initialRoute.startsWith('/book/')) {
          return [AppRouter.onGenerateRoute(RouteSettings(name: initialRoute))];
        }
        return [
          MaterialPageRoute<void>(
            builder: (_) => const _OutboxAutoStart(child: SplashScreen()),
          ),
        ];
      },
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

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
