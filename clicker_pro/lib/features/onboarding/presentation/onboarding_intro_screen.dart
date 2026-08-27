// lib/features/onboarding/presentation/onboarding_intro_screen.dart
//
// MOD-02 three-slide intro — full-bleed photo slides matching the Graphy7
// design (Graphy7 App.dc.html · MOD-02 Onboarding). Each slide is a
// background photo under a dark bottom scrim, with a mono eyebrow, a large
// 800-weight white headline and body copy. The final slide adds a full-width
// "Get Started" button; earlier slides use a round orange forward FAB. Skip
// (top-right) and dot indicators throughout.
//
// Motion tokens (MOD-04):
//   • Page indicator width tween : 240ms
//   • PageView next/back         : 320ms cubic-bezier(0.2, 0.8, 0.2, 1)
//   • Login fade route           : 320ms

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../screens/login_screen.dart';
import '../../../shared/widgets/web_shell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/onboarding_controller.dart';

class OnboardingIntroScreen extends ConsumerStatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  ConsumerState<OnboardingIntroScreen> createState() =>
      _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends ConsumerState<OnboardingIntroScreen> {
  final _pageCtrl = PageController();
  int _index = 0;

  // Design copy + assets, in order. Eyebrow tint mirrors the mockup's warm
  // highlight over each photo.
  static const _slides = <_SlideData>[
    _SlideData(
      image: 'assets/onboarding/onb-camera.jpg',
      eyebrow: 'FOR STUDIOS & FREELANCERS',
      eyebrowColor: Color(0xFFFFD9B8),
      headline: 'Every shoot,\nperfectly organised',
      body:
          'Bookings, gear, teams and packages — from first enquiry to final '
          'delivery, all in one place.',
    ),
    _SlideData(
      image: 'assets/onboarding/onb-city.jpg',
      eyebrow: 'DAY & NIGHT SHIFTS',
      eyebrowColor: Color(0xFFFFC98F),
      headline: 'Never miss\na booking again',
      body:
          'Smart calendar with conflict detection, weather alerts for outdoor '
          'shoots, and reminders that work offline.',
    ),
    _SlideData(
      image: 'assets/onboarding/onb-clock.jpg',
      eyebrow: 'ON TIME, EVERY TIME',
      eyebrowColor: Color(0xFFFFD9B8),
      headline: 'Get paid faster,\ntrack every taka',
      body:
          'Auto invoices, advance & due tracking and bKash payouts — your '
          'studio finances, always clear.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _next() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.2, 0.8, 0.2, 1),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-bleed photo slides.
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _Slide(data: _slides[i], index: i),
          ),

          // Skip — top right (hidden on the last slide where CTA takes over).
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLast ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: AppText.bodyFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls: dots + forward or final CTA.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 0, 34, 30),
                child: WebFormWidth(
                  maxWidth: 560,
                  child: isLast ? _lastControls() : _pagerControls(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slides 1–2: dots on the left, round orange forward FAB on the right.
  Widget _pagerControls() {
    return Row(
      children: [
        _dots(),
        const Spacer(),
        GestureDetector(
          onTap: _next,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.7),
                  blurRadius: 24,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Slide 3: full-width Get Started, dots centred below.
  Widget _lastControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _finish,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.7),
                    blurRadius: 28,
                    spreadRadius: -10,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontFamily: AppText.bodyFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _dots(),
      ],
    );
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _slides.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.only(right: 7),
          width: i == _index ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == _index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data, required this.index});
  final _SlideData data;
  final int index;

  // Signal-Orange ramp used for the web backdrop (no photos on web — the
  // onboarding reads as pure theme). Each slide picks a different pair so the
  // three pages feel distinct while staying on-brand.
  static const List<List<Color>> _webRamps = [
    [Color(0xFFF9A52E), Color(0xFFE2620E)], // amber → signal orange
    [Color(0xFFF4881C), Color(0xFFB84E0A)], // bright → deep
    [Color(0xFFEA7414), Color(0xFFC0530B)], // mid → dark
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop. On WEB: a Signal-Orange gradient with a soft radial glow
        // (theme-driven, no photo/video per Heaven's brief). On MOBILE: the
        // original full-bleed photo slide, untouched.
        if (kIsWeb)
          _WebBackdrop(colors: _webRamps[index % _webRamps.length])
        else
          Image.asset(
            data.image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: AppColors.orange),
          ),
        // Dark bottom scrim so the copy stays legible over any backdrop.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x52140A00), // ~0.32 near the top
                Color(0x00140A00),
                Color(0x1A140A00),
                Color(0xDB140A00), // ~0.86 at the bottom
              ],
              stops: [0.0, 0.26, 0.42, 1.0],
            ),
          ),
        ),
        // Copy pinned to the lower area, above the controls. On web the copy
        // column is capped to a comfortable reading width and centred so it
        // does not stretch across a wide desktop window.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 118),
            child: WebFormWidth(
              maxWidth: 560,
              child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.eyebrow,
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: data.eyebrowColor,
                    letterSpacing: 0.16 * 10,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.headline,
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.04,
                    letterSpacing: -0.035 * 34,
                    shadows: const [
                      Shadow(color: Color(0x73000000), blurRadius: 16, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.body,
                  style: TextStyle(
                    fontFamily: AppText.bodyFontFamily,
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.6,
                    shadows: const [
                      Shadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Web-only onboarding backdrop: a Signal-Orange diagonal gradient with a
/// soft off-centre radial glow, echoing the warm depth of the palm-shadow
/// login art without any photo. Pure theme, per Heaven's brief.
class _WebBackdrop extends StatelessWidget {
  const _WebBackdrop({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        // Warm highlight bloom, top-right — gives the flat gradient depth.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.7, -0.6),
              radius: 1.1,
              colors: [Color(0x66FFD9A8), Color(0x00FFD9A8)],
              stops: [0.0, 0.7],
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.image,
    required this.eyebrow,
    required this.eyebrowColor,
    required this.headline,
    required this.body,
  });
  final String image;
  final String eyebrow;
  final Color eyebrowColor;
  final String headline;
  final String body;
}
