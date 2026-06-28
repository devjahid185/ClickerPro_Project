// lib/features/bookings/presentation/widgets/assignments_section.dart
//
// Renders the booking's assignments list. Two visibility rules apply:
//
//   • Freelancer roles see ONLY their own assignment row (Property 4).
//   • The Payout column is hidden when the booking's
//     `hidePaymentFromTeam` flag + the active role disqualify the
//     viewer (Property 3, identical to the payment summary card gate).
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Components and Interfaces". Validates Requirements 5.4, 11.3, 11.4.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../features/settings/application/language_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/assignment.dart';
import 'detail_section.dart';

class AssignmentsSection extends ConsumerWidget {
  const AssignmentsSection({
    super.key,
    required this.assignments,
    required this.currentUserId,
    required this.currentRole,
    required this.showPayout,
    this.chiefUserId,
  });

  final List<Assignment> assignments;
  final String currentUserId;
  final UserRole currentRole;

  /// Whether the Payout column is visible. Computed at the screen level
  /// using the same `shouldShowPayment` predicate the payment summary
  /// uses, so the gating contract stays coherent across both surfaces.
  final bool showPayout;

  /// User id of the chief photographer for this booking.
  /// When set, the chief's row is highlighted with a gold star.
  final String? chiefUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    // Freelancer scope: filter to their own row only.
    final visible = currentRole == UserRole.freelancer
        ? assignments
              .where((a) => a.userId == currentUserId)
              .toList(growable: false)
        : assignments;

    return DetailSection(
      title: 'Assignments',
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                currentRole == UserRole.freelancer
                    ? 'You are not assigned to this booking.'
                    : 'No assignments yet.',
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _AssignmentRow(
                    assignment: visible[i],
                    showPayout: showPayout,
                    lang: lang,
                    isChief:
                        chiefUserId != null && visible[i].userId == chiefUserId,
                  ),
                  if (i != visible.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line(0.04),
                    ),
                ],
              ],
            ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({
    required this.assignment,
    required this.showPayout,
    required this.lang,
    this.isChief = false,
  });

  final Assignment assignment;
  final bool showPayout;
  final String lang;
  final bool isChief;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isChief
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : AppColors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isChief
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: isChief
                ? Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.gold,
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: AppColors.orange,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'User ${assignment.userId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isChief ? AppColors.gold : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isChief) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'CHIEF',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _titleCase(assignment.role.name),
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          if (showPayout) ...[
            const SizedBox(width: 8),
            Text(
              BookingFormat.money(
                assignment.payout,
                lang: lang,
                bnNumerals: lang == 'bn',
              ),
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.95),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    final spaced = input.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return spaced
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
