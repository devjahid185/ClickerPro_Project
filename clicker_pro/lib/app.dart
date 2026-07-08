import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/navigation/route_observer.dart';
import 'core/providers.dart';
import 'features/bookings/application/booking_providers.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/settings/application/currency_controller.dart';
import 'features/settings/application/language_controller.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/web_nav_shell.dart';
import 'shared/widgets/web_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'theme/reduce_motion.dart';

class ClickerProApp extends ConsumerWidget {
  const ClickerProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(activeLocaleProvider);
    final activeTheme = ref.watch(activeThemeModeProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    // Eagerly load the studio's currency preference so ActiveCurrency is set
    // before the first money render; rebuilds the tree when it resolves.
    ref.watch(currencyControllerProvider);

    // Sync the static palette so every custom-painted surface reads the active
    // theme's colours without needing a BuildContext. Web has its own theme and
    // ignores this flag.
    AppColors.active = activeTheme == AppThemeMode.noirDark
        ? ActivePalette.noirDark
        : ActivePalette.clickerPro;

    // Mobile ThemeData for the active theme (ClickerPro default or Noir dark).
    final mobileTheme = activeTheme == AppThemeMode.noirDark
        ? AppTheme.noirDark()
        : AppTheme.clickerPro();

    return MaterialApp(
      title: 'Clicker Pro',
      debugShowCheckedModeBanner: false,
      // Web uses its own neutral base theme (AppThemeWeb via WebTheme tokens);
      // mobile uses the selected theme. On web the Scaffold is made transparent
      // so the WebShell's page backdrop shows through; mobile keeps a solid one.
      theme: kIsWeb
          ? AppTheme.web().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            )
          : mobileTheme,
      // Root navigator key lets the web sidebar (mounted in `builder`, above
      // the Navigator) push routes.
      navigatorKey: rootNavigatorKey,
      // Tracks the active route so the web sidebar can highlight + gate chrome.
      navigatorObservers: [AppRouteObserver()],
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Key the routed subtree on the active theme so custom-painted widgets
      // (which read AppColors.active directly) rebuild on every theme switch.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || reduceMotion,
            // Force 12-hour AM/PM time everywhere (pickers + Material time
            // rendering) regardless of the device's 12h/24h locale setting.
            // Studios read "1 PM", not "13:00" — matches BookingFormat.clockTime.
            alwaysUse24HourFormat: false,
          ),
          child: KeyedSubtree(
            key: ValueKey(activeTheme.name),
            // Web-only glassmorphism shell; a pure pass-through on mobile.
            // On web the WebNavShell adds the permanent sidebar + content
            // panel around the routed screen, driven by the current route.
            child: WebShell(
              child: kIsWeb
                  ? ValueListenableBuilder<String>(
                      valueListenable: currentRouteName,
                      builder: (context, route, _) => WebNavShell(
                        currentRoute: route,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    )
                  : (child ?? const SizedBox.shrink()),
            ),
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
            // Name the boot route so the route observer tracks it (and the web
            // shell treats splash as fullscreen — no sidebar over the splash).
            settings: const RouteSettings(name: RouteNames.splash),
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
