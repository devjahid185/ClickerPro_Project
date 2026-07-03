// lib/features/auth/presentation/role_change_dialog.dart
//
// Clicker Pro — Role Change Dialog (Dark Luxury Lens)
//
// Stateful dialog. Shows the current role at top, a list of selectable
// target roles (excluding current and Manager — Manager is invite-only),
// and a disclosure block listing capabilities lost in the proposed role.
//
// Per Requirement 3.10: Cancel must NOT trigger any network call. The
// caller (Profile screen) is responsible for invoking
// `sessionController.changeRole(newRole)` after this dialog returns.
//
// Usage:
//   final picked = await RoleChangeDialog.show(context, current);
//   if (picked != null) await sessionController.changeRole(picked);

import 'package:flutter/material.dart';

import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../domain/user_role.dart';

class RoleChangeDialog extends StatefulWidget {
  const RoleChangeDialog._({required this.currentRole});

  final UserRole currentRole;

  /// Returns the selected target role, or `null` if the user cancelled.
  static Future<UserRole?> show(BuildContext ctx, UserRole currentRole) {
    return showGeneralDialog<UserRole?>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Role change',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => RoleChangeDialog._(currentRole: currentRole),
      transitionBuilder: (_, anim, _, child) {
        final scale = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  State<RoleChangeDialog> createState() => _RoleChangeDialogState();
}

class _RoleChangeDialogState extends State<RoleChangeDialog> {
  UserRole? _selected;

  /// All roles a user can pick — exclude the current role and Manager
  /// (Manager is invite-bound, not selectable).
  List<UserRole> get _targets => UserRole.values
      .where((r) => r != widget.currentRole && r != UserRole.manager)
      .toList(growable: false);

  /// Capabilities the user currently has but would lose under [target].
  List<Capability> _lostCapabilities(UserRole target) {
    final current = RolePolicy(widget.currentRole);
    final next = RolePolicy(target);
    return Capability.values
        .where((c) => current.can(c) && !next.can(c))
        .toList(growable: false);
  }

  String _humanLabel(Capability c) {
    switch (c) {
      case Capability.editStudioBranding:
        return 'Edit studio branding';
      case Capability.editGearInventory:
        return 'Manage gear inventory';
      case Capability.joinAnotherStudio:
        return 'Join another studio';
      case Capability.viewFinancials:
        return 'View financial summaries';
      case Capability.viewTeamSection:
        return 'View team section';
      case Capability.toggleDistribution:
        return 'Toggle revenue distribution';
      case Capability.toggleVat:
        return 'Toggle VAT';
      case Capability.changeRole:
        return 'Change role';
      case Capability.generateTeamInvite:
        return 'Generate team invites';
      case Capability.deleteOwnAccount:
        return 'Delete own account';
      // ── Bookings module ──────────────────────────────────
      case Capability.viewAllBookings:
        return 'View all bookings';
      case Capability.viewAssignedBookings:
        return 'View assigned bookings';
      case Capability.viewOwnBookings:
        return 'View own bookings';
      case Capability.createBooking:
        return 'Create bookings';
      case Capability.createOwnBooking:
        return 'Log own bookings';
      case Capability.editBooking:
        return 'Edit bookings';
      case Capability.deleteBooking:
        return 'Delete bookings';
      case Capability.advanceBookingStatus:
        return 'Advance booking status';
      case Capability.cancelBooking:
        return 'Cancel bookings';
      case Capability.viewBookingPayments:
        return 'View booking payments';
      case Capability.viewBookingPayouts:
        return 'View booking payouts';
      case Capability.editBookingPayments:
        return 'Edit booking payments';
      case Capability.editAssignment:
        return 'Edit assignments';
      case Capability.toggleHidePayment:
        return 'Toggle hide-payment-from-team';
      case Capability.generatePublicBookingToken:
        return 'Generate public booking links';
      case Capability.approvePublicBooking:
        return 'Approve public booking requests';
      case Capability.requestReEdit:
        return 'Request re-edits';
      case Capability.assignReEdit:
        return 'Assign re-edits';
      case Capability.updateTaskProgress:
        return 'Update task progress';
      case Capability.createAnnouncement:
        return 'Create announcements';
      case Capability.viewAnnouncements:
        return 'View announcements';
      // ── Studio-management surfaces ───────────────────────
      case Capability.accessTeam:
        return 'Access team & staff';
      case Capability.accessInvoice:
        return 'Access invoices';
      case Capability.accessTax:
        return 'Access tax / VAT';
      case Capability.accessPackages:
        return 'Manage packages';
      case Capability.accessDelivery:
        return 'Access delivery system';
      case Capability.accessDailyTasks:
        return 'Access daily tasks';
      case Capability.accessFollowup:
        return 'Access client follow-up';
      case Capability.accessReminders:
        return 'Access reminders';
      case Capability.accessWaitlist:
        return 'Access waitlist';
      case Capability.accessRentTracking:
        return 'Access rent tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lost = _selected != null ? _lostCapabilities(_selected!) : const [];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (fixed) ────────────────────────────────
              Text(
                'Change role',
                style: TextStyle(
                  fontFamily: AppText.bodyFontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.film,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CURRENT · ${widget.currentRole.displayLabel.toUpperCase()}',
                style: TextStyle(
                  fontFamily: AppText.bodyFontFamily,
                  fontSize: 10.5,
                  letterSpacing: 2,
                  color: AppColors.gold.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),

              // ── Scrollable middle: roles + lost-capabilities ──
              // Without this, a long "you will lose access to" list pushed
              // the Cancel/Confirm buttons off-screen so role change was
              // impossible. The buttons below now stay fixed and visible.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              // ── Target list ───────────────────────────────────
              for (final r in _targets) ...[
                _RoleOption(
                  role: r,
                  selected: _selected == r,
                  onTap: () => setState(() => _selected = r),
                ),
                const SizedBox(height: 8),
              ],

              // ── Disclosure: capabilities lost ─────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _selected == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.line(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.gold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'You will lose access to:',
                                    style: TextStyle(
                                      fontFamily: AppText.bodyFontFamily,
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (lost.isEmpty)
                                Text(
                                  'No capabilities will be lost.',
                                  style: TextStyle(
                                    color: AppColors.filmDim.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 12.5,
                                  ),
                                )
                              else
                                for (final c in lost.cast<Capability>())
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _humanLabel(c),
                                            style: TextStyle(
                                              color: AppColors.film.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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

              const SizedBox(height: 20),

              // ── Buttons (fixed, always visible) ───────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.filmDim,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: AppColors.line(0.12),
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ConfirmButton(
                      enabled: _selected != null,
                      onTap: _selected == null
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role option row ─────────────────────────────────────────────
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  String _description(UserRole r) {
    switch (r) {
      case UserRole.owner:
        return 'Company operator. Full access to branding, finance, team.';
      case UserRole.freelancer:
        return 'Solo photographer. Personal gear and clients only.';
      case UserRole.both:
        return 'Hybrid. Inherits Owner and Freelancer capabilities.';
      case UserRole.manager:
        return 'Invite-only. Cannot self-register.';
      case UserRole.webAdmin:
        return 'Platform administrator. Full system access.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withValues(alpha: 0.12)
              : AppColors.line(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.orange.withValues(alpha: 0.6)
                : AppColors.line(0.08),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.orange : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.orange
                      : Colors.black.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.film,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayLabel,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _description(role),
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm button ──────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.orange,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
