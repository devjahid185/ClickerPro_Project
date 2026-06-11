// lib/features/onboarding/presentation/onboarding_intro_screen.dart
//
// MOD-02 three-slide intro. PageView with Skip / dot-indicator / Next-Done.
// Done (or Skip) marks `onboarding_complete` and pushes Login with a fade
// transition.
//
// Motion tokens (MOD-04):
//   • Page indicator width tween : 240ms (default curve)
//   • PageView next/back         : 320ms cubic-bezier(0.2, 0.8, 0.2, 1)
//   • Login fade route           : 320ms

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../screens/login_screen.dart';
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

  static const _slides = <_SlideData>[
    _SlideData(
      icon: Icons.event_available_rounded,
      headlineEn: 'Manage every booking',
      bodyEn:
          'From inquiry to delivery — your studio in one app, online or offline.',
      headlineBn: 'প্রতিটি বুকিং সামলান',
      bodyBn:
          'প্রথম ইনকোয়ারি থেকে ডেলিভারি — পুরো স্টুডিও এক জায়গায়, অনলাইনে বা অফলাইনে।',
    ),
    _SlideData(
      icon: Icons.groups_2_rounded,
      headlineEn: 'One app for every role',
      bodyEn:
          'Owner, freelancer, or both — Clicker Pro adapts to how you work.',
      headlineBn: 'প্রতিটি রোলের জন্য এক অ্যাপ',
      bodyBn:
          'Owner, Freelancer অথবা Both — যেভাবে কাজ করেন, Clicker Pro সেভাবেই গড়ে উঠবে।',
    ),
    _SlideData(
      icon: Icons.translate_rounded,
      headlineEn: 'English & বাংলা — your call',
      bodyEn: 'Switch language any time. Bengali numerals optional.',
      headlineBn: 'ইংরেজি ও বাংলা — আপনার পছন্দ',
      bodyBn: 'যেকোনো সময় ভাষা পাল্টান। চাইলে বাংলা সংখ্যাও দেখান।',
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

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isBn = lang == 'bn';
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // Subtle watermark — the blade-flower brand mark, same motif as
          // the landing page so onboarding and site read as one product.
          // IgnorePointer keeps it from ever blocking touches.
          Positioned(
            left: -100,
            top: -60,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: Image.asset(
                  'assets/brand/logo_flower.png',
                  width: 360,
                  height: 360,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip top right.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.filmDim,
                        ),
                        child: Text(
                          isBn ? 'এড়িয়ে যান' : 'Skip',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _Slide(data: _slides[i], isBn: isBn),
                  ),
                ),

                // Indicator + Next/Done.
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _index ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? AppColors.orange
                                  : AppColors.gray300,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            if (isLast) {
                              _finish();
                            } else {
                              _pageCtrl.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: const Cubic(0.2, 0.8, 0.2, 1),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast
                                    ? (isBn ? 'শুরু করুন' : 'Get Started')
                                    : (isBn ? 'পরবর্তী' : 'Next'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data, required this.isBn});
  final _SlideData data;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final headline = isBn ? data.headlineBn : data.headlineEn;
    final body = isBn ? data.bodyBn : data.bodyEn;
    final headlineStyle = isBn
        ? GoogleFonts.notoSansBengali(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.film,
            height: 1.2,
          )
        : TextStyle(
            fontFamily: AppText.brand.fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.film,
            height: 1.15,
          );
    final bodyStyle = isBn
        ? GoogleFonts.notoSansBengali(
            fontSize: 14,
            color: AppColors.filmDim,
            height: 1.6,
          )
        : const TextStyle(
            fontSize: 14.5,
            color: AppColors.filmDim,
            height: 1.55,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon block.
          Center(
            child: Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1FFF5A1F),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.45),
                    width: 1.4,
                  ),
                ),
                child: Icon(data.icon, color: AppColors.orange, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(headline, style: headlineStyle),
          const SizedBox(height: 12),
          Text(body, style: bodyStyle),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.headlineEn,
    required this.bodyEn,
    required this.headlineBn,
    required this.bodyBn,
  });
  final IconData icon;
  final String headlineEn;
  final String bodyEn;
  final String headlineBn;
  final String bodyBn;
}
