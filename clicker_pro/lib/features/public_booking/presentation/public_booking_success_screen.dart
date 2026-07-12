// lib/features/public_booking/presentation/public_booking_success_screen.dart
//
// Final screen of the public booking flow. Renders a thank-you state
// after the visitor's request is accepted by the server. This is the END
// of the public flow — the visitor is not a signed-in user, so we never
// forward them into the app's splash → onboarding → login. Doing that was
// the "self-booking confirm করার পরে আবার অনবোর্ডিং ও লগিন আসে" bug.
//
// Arguments (via `Navigator.pushReplacementNamed`'s `arguments`) is a
// `PublicBookingSuccessArgs` carrying the request id and the studio name so
// the visitor can see exactly which studio they booked with.

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Navigation payload for [PublicBookingSuccessScreen]. Kept as a small value
/// object so the success screen can show the studio the visitor booked with.
class PublicBookingSuccessArgs {
  const PublicBookingSuccessArgs({required this.requestId, this.studioName});
  final String? requestId;
  final String? studioName;
}

class PublicBookingSuccessScreen extends StatelessWidget {
  const PublicBookingSuccessScreen({super.key, this.requestId, this.studioName});
  final String? requestId;
  final String? studioName;

  @override
  Widget build(BuildContext context) {
    final shortRef = (requestId != null && requestId!.length > 8)
        ? requestId!.substring(0, 8).toUpperCase()
        : (requestId?.toUpperCase() ?? '—');
    final studio = (studioName ?? '').trim();
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
              // Show WHICH studio the request went to — the visitor may have
              // opened the link without knowing the studio's exact name.
              if (studio.isNotEmpty) ...[
                Text(
                  'Booked with',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                    color: AppColors.filmMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 10),
              ],
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
              // The public flow ends here. The visitor is not an app user, so
              // there is nothing to navigate to — a "Done" button used to push
              // the splash route, which dumped them into onboarding/login. We
              // simply tell them they can close the page.
              Text(
                'You can close this page now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
