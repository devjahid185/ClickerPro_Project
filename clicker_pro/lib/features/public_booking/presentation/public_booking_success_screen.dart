// lib/features/public_booking/presentation/public_booking_success_screen.dart
//
// Final screen of the public booking flow. Renders a thank-you state
// after the visitor's request is accepted by the server.
//
// `requestId` is passed via `Navigator.pushReplacementNamed`'s
// `arguments`. We display a short reference number derived from it so
// the visitor can quote it later if they need to follow up.

import 'package:flutter/material.dart';

import '../../../core/navigation/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class PublicBookingSuccessScreen extends StatelessWidget {
  const PublicBookingSuccessScreen({super.key, this.requestId});
  final String? requestId;

  @override
  Widget build(BuildContext context) {
    final shortRef = (requestId != null && requestId!.length > 8)
        ? requestId!.substring(0, 8).toUpperCase()
        : (requestId?.toUpperCase() ?? '—');
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Request received',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thanks for booking with us. The studio team will review '
                'your request and reach out shortly to confirm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmDim,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.line(0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REF',
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 10.5,
                        letterSpacing: 1.4,
                        color: AppColors.filmMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      shortRef,
                      style: TextStyle(
                        color: AppColors.film,
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // The form pushReplace()s into this screen, so when the
                    // flow was opened from a deep link there is nothing left
                    // to pop and Done used to silently do nothing. Fall back
                    // to the splash route, which forwards to dashboard or
                    // login based on the current session.
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      nav.pushNamedAndRemoveUntil(
                        RouteNames.splash,
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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
