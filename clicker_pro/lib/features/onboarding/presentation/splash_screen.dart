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

import '../../../core/providers.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../screens/login_screen.dart';
import '../../../theme/app_colors.dart';
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
      session = await ref
          .read(authRepositoryProvider)
          .restoreSession()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      session = null;
    }

    if (session != null) {
      await dwell.future;
      if (_disposed || !mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(_fadeRoute(const DashboardScreen()));
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
    if (!isDone) {
      next = const OnboardingIntroScreen();
    } else {
      next = const LoginScreen();
    }

    if (_disposed || !mounted) return;
    Navigator.of(context).pushReplacement(_fadeRoute(next));
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder(
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
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // Ambient orange glow blob top-right.
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFF5A1F),
              ),
            ),
          ),
          // Ambient gold glow blob bottom-left.
          Positioned(
            bottom: -90,
            left: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x14C9A84C),
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
                          width: 130 * pulse,
                          height: 130 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withValues(
                              alpha: 0.1 * pulse,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _logoFade.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.orange,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 24,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _brandFade,
                  child: const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: AppColors.film,
                        letterSpacing: 0.4,
                      ),
                      children: [
                        TextSpan(text: 'Clicker '),
                        TextSpan(
                          text: 'Pro',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _brandFade,
                  child: Text(
                    'COMPANY MANAGEMENT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9.5,
                      letterSpacing: 2.6,
                      color: AppColors.filmDim.withValues(alpha: 0.65),
                    ),
                  ),
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
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: AppColors.filmDim.withValues(alpha: 0.4),
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
