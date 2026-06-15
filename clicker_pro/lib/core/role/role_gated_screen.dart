// lib/core/role/role_gated_screen.dart
//
// Route-level role guard. Wrap a screen in the router so it renders the real
// [child] only when the signed-in user's role holds [capability]; otherwise it
// shows an "access restricted" placeholder.
//
// This is the hard enforcement layer: hiding a drawer item stops the *casual*
// path, but a deep link / programmatic pushNamed would still reach a screen.
// Gating the route closes that hole in ONE place per route.
//
// ```
// case RouteNames.team:
//   return lensPageRoute<void>(
//     const RoleGatedScreen(
//       capability: Capability.accessTeam,
//       title: 'Team & Staff',
//       child: TeamScreen(),
//     ),
//   );
// ```

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/profile_controllers.dart';
import '../../shared/states/lens_loader.dart';
import '../../theme/app_colors.dart';
import 'capability.dart';
import 'role_policy.dart';

class RoleGatedScreen extends ConsumerWidget {
  const RoleGatedScreen({
    super.key,
    required this.capability,
    required this.title,
    required this.child,
  });

  final Capability capability;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    // Role is a security boundary, not a feature flag: until we actually know
    // the role, show a loader rather than optimistically rendering the screen.
    return userAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.voidBlack,
        body: const Center(child: LensLoader()),
      ),
      error: (_, _) => _denied(context),
      data: (user) {
        if (user == null) return _denied(context);
        return RolePolicy(user.role).can(capability) ? child : _denied(context);
      },
    );
  }

  Widget _denied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.filmDim.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.filmDim,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Not available for your role',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$title is managed by the studio owner or manager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
