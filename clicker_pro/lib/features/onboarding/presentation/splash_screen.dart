// lib/features/onboarding/presentation/splash_screen.dart
//
// MOD-02 Splash. Owns the launch dwell + brand animation, then routes to:
//   - LanguagePickerScreen  if onboarding flag is false
//   - LoginScreen           otherwise
//
// Backend session restoration is intentionally skipped so the splash never
// blocks on a network call. Once the backend is connected, restore the
// session-aware routing in _route().
//
// Motion tokens (MOD-02):
//   • Logo fade-in            : 0 → 1 over the first 45% of 1100ms (Curves.easeOut)
//   • Logo scale              : 0.8 → 1.0 elastic-out across 1100ms
//   • Brand fade              : 0 → 1 from 40% → 100% (Curves.easeOutCubic) so the logo lands first
//   • Gold/orange halo pulse  : 1500ms loop, reverse, drives radius + opacity
//   • Route transition (out)  : 320ms fade

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../screens/login_screen.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/clicker_logo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../auth/domain/session.dart';
import '../application/onboarding_controller.dart';
import 'onboarding_intro_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _brandFade;

  Timer? _dwellTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _logoScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _brandFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
    );

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _logoCtrl.forward();
    _route();
  }

  Future<void> _route() async {
    // Run the splash for at least 1500ms regardless of data load.
    final dwell = Completer<void>();
    _dwellTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!dwell.isCompleted) dwell.complete();
    });

    // Try to restore session (checks SecureStore for JWT token).
    // If valid token exists, skip login and go straight to dashboard.
    Session? session;
    try {
      // Local-first restore returns in milliseconds when a session is
      // cached; the generous timeout only guards the cold "token but no
      // cache" network path.
      session = await ref
          .read(authRepositoryProvider)
          .restoreSession()
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      session = null;
    }

    if (session != null) {
      await dwell.future;
      if (_disposed || !mounted) return;
      Navigator.of(context).pushReplacement(
        _fadeRoute(const DashboardScreen(), name: RouteNames.dashboard),
      );
      return;
    }

    // No session — check onboarding flag.
    bool isDone = false;
    try {
      final result = await ref
          .read(onboardingControllerProvider)
          .isComplete()
          .timeout(const Duration(seconds: 4));
      isDone = result;
    } catch (_) {
      isDone = false;
    }

    await dwell.future;
    if (_disposed || !mounted) return;

    // Language is no longer chosen up-front — it defaults and can be changed
    // anytime in Settings. First launch goes straight to the intro.
    final Widget next;
    final String nextName;
    if (!isDone) {
      next = const OnboardingIntroScreen();
      nextName = RouteNames.onboarding;
    } else {
      next = const LoginScreen();
      nextName = RouteNames.login;
    }

    if (_disposed || !mounted) return;
    Navigator.of(context)
        .pushReplacement(_fadeRoute(next, name: nextName));
  }

  PageRouteBuilder<void> _fadeRoute(Widget page, {String? name}) {
    return PageRouteBuilder(
      // Naming the route lets the web route observer track it, so the web shell
      // correctly shows the sidebar on /dashboard and hides it on /login.
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _dwellTimer?.cancel();
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen brand splash image (dark→sunset gradient). Scaffold sits
      // on black so there is no seam behind the cover-fitted image.
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── FULL-SCREEN SPLASH IMAGE ────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/Sphlash/Sphlash.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gentle scrim so the white wordmark stays crisp over the brightest
          // part of the gradient.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.30),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                  builder: (_, _) {
                    final pulse = 0.85 + (_pulseCtrl.value * 0.15);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 172 * pulse,
                          height: 172 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Soft white halo reads over the sunset image.
                            color: Colors.white.withValues(alpha: 0.12 * pulse),
                          ),
                        ),
                        Opacity(
                          opacity: _logoFade.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            // The Graphy7 G7 brand mark — the first thing the
                            // user sees, matching the launcher icon.
                            child: const ClickerLogo(size: 132),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _brandFade,
                  child: Text.rich(
                    TextSpan(
                      // Design wordmark: Hanken 800, "Pro" orange, NOT italic,
                      // tight tracking (matches dashboard + login chrome).
                      style: TextStyle(
                        fontFamily: AppText.brandFontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        // White over the sunset image; "Pro" keeps brand orange.
                        color: Colors.white,
                        letterSpacing: -0.03 * 30,
                      ),
                      children: [
                        TextSpan(text: 'Graphy'),
                        TextSpan(
                          text: '7',
                          style: TextStyle(color: AppColors.orange),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _brandFade,
                  child: Text(
                    'PHOTOGRAPHY MANAGEMENT',
                    style: TextStyle(
                      fontFamily: AppText.bodyFontFamily,
                      fontSize: 9.5,
                      letterSpacing: 2.6,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                // Small brand loader so the splash reads as "opening", not
                // frozen — fades in with the wordmark and spins the aperture
                // iris until the route transitions away.
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _brandFade,
                  child: const LensLoader(size: 26),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _brandFade,
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: AppText.bodyFontFamily,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
