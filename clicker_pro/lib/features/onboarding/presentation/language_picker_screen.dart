// lib/features/onboarding/presentation/language_picker_screen.dart
//
// MOD-02 + MOD-48 first-launch language pre-pick. The user taps a card to set
// the language; the choice is persisted via LanguageController, the card lights
// up with a gold ring, and the Continue button activates.
//
// Motion tokens (MOD-04):
//   • Card highlight transition : 220ms easeOut
//   • Continue route push       : 280ms slide-from-right + fade,
//                                 cubic-bezier(0.2, 0.8, 0.2, 1)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../settings/application/language_controller.dart';
import 'onboarding_intro_screen.dart';

class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String? _selected;

  void _select(String code) {
    setState(() => _selected = code);
    ref.read(languageControllerProvider.notifier).setLanguage(code);
  }

  void _continue() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => const OnboardingIntroScreen(),
        transitionsBuilder: (_, anim, _, child) {
          final tween = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: const Cubic(0.2, 0.8, 0.2, 1)));
          return SlideTransition(
            position: anim.drive(tween),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose your\nlanguage',
                style: TextStyle(
                  fontFamily: AppText.brand.fontFamily,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.film,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You can change this later in Settings.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.filmDim.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 34),

              _LangCard(
                primary: 'English',
                secondary: 'Default',
                isSelected: _selected == 'en',
                onTap: () => _select('en'),
              ),
              const SizedBox(height: 14),
              _LangCard(
                primary: 'বাংলা',
                secondary: 'Bengali',
                primaryStyle: GoogleFonts.notoSansBengali(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.film,
                ),
                isSelected: _selected == 'bn',
                onTap: () => _select('bn'),
              ),

              const Spacer(),

              AnimatedOpacity(
                opacity: _selected == null ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 220),
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _selected == null ? null : _continue,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.primary,
    required this.secondary,
    required this.isSelected,
    required this.onTap,
    this.primaryStyle,
  });

  final String primary;
  final String secondary;
  final bool isSelected;
  final VoidCallback onTap;
  final TextStyle? primaryStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orangeSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.orange : AppColors.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary,
                      style:
                          primaryStyle ??
                          TextStyle(
                            fontFamily: AppText.brand.fontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.film,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondary.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        letterSpacing: 1.6,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.filmDim.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
