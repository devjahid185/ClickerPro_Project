// lib/features/bookings/presentation/booking_detail_screen.dart
//
// Read-only booking detail surface. Renders the eight sections in the
// order pinned by Requirement 5.2 — header, client info, schedule,
// package, payment summary, assignments, status timeline, re-edit
// requests (placeholder for the next slice).
//
// Capability gating:
//   • Edit (app bar)             — `Capability.editBooking`
//   • Advance status (FAB)       — `Capability.advanceBookingStatus`
//   • Cancel (overflow)          — `Capability.cancelBooking`
//   • Payment summary card       — `shouldShowPayment(role, hide, can)`
//   • Assignments payout column  — same predicate as above
//   • Assignments self-only      — Freelancer role
//
// The booking is delivered by the family-keyed `BookingDetailController`
// which handles local-first load + background remote refresh +
// transition + cancel. The screen never reads from the repository
// directly; it only invokes the controller's actions.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Booking Detail Screen". Validates Requirements 5.1–5.11, 3.4, 3.5,
// 3.7, 3.8, 7.1.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/booking_status/booking_status_machine.dart';
import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/notifications/event_reminder_service.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/status_conflict_listener.dart';
import '../../../theme/app_colors.dart';
import '../../auth/domain/user_role.dart';
import '../../profile/application/profile_controllers.dart';
import '../../settings/application/language_controller.dart';
import '../../team/application/team_providers.dart';
import '../../team/domain/team_member.dart';
import '../application/booking_detail_controller.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_detail_envelope.dart';
import '../domain/shift.dart';
import 'booking_list_screen.dart'
    show shouldShowPayment, shouldShowPaymentInShare;
import 'widgets/assignments_section.dart';
import 'widgets/booking_status_badge.dart';
import 'widgets/detail_section.dart';
import 'widgets/payment_summary_card.dart';
import 'widgets/re_edit_section.dart';
import 'widgets/status_timeline.dart';
import 'widgets/task_progress_section.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookingDetailControllerProvider(bookingId));
    final policy = ref.watch(bookingsPolicyProvider);
    final currentUserId = ref.watch(bookingsCurrentUserIdProvider) ?? '';
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    return StatusConflictListener(
      child: Scaffold(
        backgroundColor: AppColors.voidBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.film),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Booking',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (policy.can(Capability.editBooking))
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_outlined, color: AppColors.gold),
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).pushNamed(RouteNames.bookingEdit, arguments: bookingId);
                  // After returning, refresh the detail in case the user
                  // saved changes.
                  if (!context.mounted) return;
                  await ref
                      .read(bookingDetailControllerProvider(bookingId).notifier)
                      .refresh();
                },
              ),
            PopupMenuButton<_DetailMenuAction>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: AppColors.voidElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.line(0.08)),
              ),
              itemBuilder: (_) {
                final canCancel = policy.can(Capability.cancelBooking);
                return [
                  if (canCancel)
                    PopupMenuItem(
                      value: _DetailMenuAction.cancel,
                      child: Text(
                        'Cancel booking',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  PopupMenuItem(
                    value: _DetailMenuAction.calendar,
                    child: Text(
                      'Add to Google Calendar',
                      style: TextStyle(color: AppColors.film),
                    ),
                  ),
                  PopupMenuItem(
                    value: _DetailMenuAction.refresh,
                    child: Text(
                      'Refresh from server',
                      style: TextStyle(color: AppColors.film),
                    ),
                  ),
                ];
              },
              onSelected: (action) async {
                switch (action) {
                  case _DetailMenuAction.cancel:
                    await _handleCancel(context, ref);
                    break;
                  case _DetailMenuAction.calendar:
                    final env = ref
                        .read(bookingDetailControllerProvider(bookingId))
                        .value;
                    if (env != null) _addToGoogleCalendar(env.booking);
                    break;
                  case _DetailMenuAction.refresh:
                    await ref
                        .read(
                          bookingDetailControllerProvider(bookingId).notifier,
                        )
                        .refresh();
                    break;
                }
              },
            ),
          ],
        ),
        floatingActionButton: detailAsync.maybeWhen(
          data: (envelope) {
            final next = BookingStatusMachine.nextForward(
              envelope.booking.status,
            );
            if (next == null) return null;
            if (!policy.can(Capability.advanceBookingStatus)) return null;
            if (!BookingStatusMachine.canRoleApply(
              policy.role,
              envelope.booking.status,
              next,
            )) {
              return null;
            }
            return FloatingActionButton.extended(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text('Move to ${_titleCase(next.name)}'),
              onPressed: () => _handleAdvance(context, ref, next),
            );
          },
          orElse: () => null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.orange,
                  backgroundColor: AppColors.voidElevated,
                  onRefresh: () => ref
                      .read(bookingDetailControllerProvider(bookingId).notifier)
                      .refresh(),
                  child: detailAsync.when(
                    loading: () => const _ScrollableSlot(child: LensLoader()),
                    error: (err, _) => _ScrollableSlot(
                      child: ErrorState(
                        message: 'Could not load this booking.',
                        onRetry: () => ref.invalidate(
                          bookingDetailControllerProvider(bookingId),
                        ),
                      ),
                    ),
                    data: (envelope) => _DetailBody(
                      envelope: envelope,
                      policy: ref.watch(bookingsPolicyProvider),
                      currentUserId: currentUserId,
                      lang: lang,
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

  Future<void> _handleAdvance(
    BuildContext context,
    WidgetRef ref,
    BookingStatus to,
  ) async {
    // Chronology guard: Shot Complete / Delivered / Completed can only
    // be marked AFTER the event's end time — a future event can't
    // already be done.
    final booking = ref
        .read(bookingDetailControllerProvider(bookingId))
        .valueOrNull
        ?.booking;
    if (booking != null &&
        !BookingStatusMachine.isTimeAllowed(
          to,
          booking.date,
          booking.endTime,
        )) {
      _showSnack(
        context,
        'Event time (${booking.date.day}/${booking.date.month} ${booking.endTime}) '
        'cannot mark "${_titleCase(to.name)}" before it has ended.',
      );
      return;
    }
    try {
      await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .transitionStatus(to);
      if (!context.mounted) return;
      _showSnack(context, 'Status updated to ${_titleCase(to.name)}.');
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not update status: $e');
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final reason = await _CancelReasonDialog.show(context);
    // `null` = the user backed out. An empty string = confirmed cancel
    // with no reason given (reason is optional now).
    if (reason == null) return;
    try {
      await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .cancel(reason.isEmpty ? 'No reason provided' : reason);
      // A cancelled event shouldn't still ping its 1-hour reminder.
      EventReminderService.instance.cancelForBooking(bookingId);
      if (!context.mounted) return;
      _showSnack(context, 'Booking cancelled.');
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not cancel: $e');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Force a light label: the dark `voidElevated` background + the
          // theme's default (dark) snackbar text rendered error messages
          // invisible (dark-on-dark) in light mode.
          content: Text(
            message,
            style: TextStyle(color: AppColors.film),
          ),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.envelope,
    required this.policy,
    required this.currentUserId,
    required this.lang,
  });

  final BookingDetailEnvelope envelope;
  final dynamic policy; // RolePolicy — typed dynamic to avoid extra import
  final String currentUserId;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final booking = envelope.booking;
    final canViewPayments = policy.can(Capability.viewBookingPayments) as bool;
    final showPayment = shouldShowPayment(
      role: policy.role as UserRole,
      hidePaymentFromTeam: booking.hidePaymentFromTeam,
      canViewPayments: canViewPayments,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _HeaderCard(booking: booking, lang: lang),
        if (envelope.client != null)
          DetailSection(
            title: 'Client',
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: envelope.client!.name,
                ),
                DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: envelope.client!.phone,
                  valueColor: AppColors.teal,
                  onTap: () =>
                      launchUrl(Uri.parse('tel:${envelope.client!.phone}')),
                  trailing: envelope.client!.phone.isEmpty
                      ? null
                      : CallIconButton(
                          onTap: () => launchUrl(
                            Uri.parse('tel:${envelope.client!.phone}'),
                          ),
                        ),
                ),
                if (envelope.client!.email != null)
                  DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: envelope.client!.email,
                  ),
                if (envelope.client!.address != null)
                  DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Address',
                    value: envelope.client!.address,
                  ),
                if (booking.eventType.requiresBrideGroom) ...[
                  if (booking.brideName != null)
                    DetailRow(
                      icon: Icons.favorite_outline,
                      label: 'Bride',
                      value: booking.brideName,
                    ),
                  if (booking.groomName != null)
                    DetailRow(
                      icon: Icons.favorite_outline,
                      label: 'Groom',
                      value: booking.groomName,
                    ),
                ],
              ],
            ),
          ),
        // The booking itself carries client name/phone even when the
        // linked Client row hasn't synced — never hide the contact info.
        if (envelope.client == null &&
            (booking.clientName != null || booking.clientPhone != null))
          DetailSection(
            title: 'Client',
            child: Column(
              children: [
                if (booking.clientName != null)
                  DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: booking.clientName,
                  ),
                if (booking.clientPhone != null)
                  DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: booking.clientPhone,
                    valueColor: AppColors.teal,
                    onTap: () =>
                        launchUrl(Uri.parse('tel:${booking.clientPhone}')),
                    trailing: CallIconButton(
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${booking.clientPhone}')),
                    ),
                  ),
              ],
            ),
          ),
        DetailSection(
          title: 'Schedule',
          child: Column(
            children: [
              DetailRow(
                icon: Icons.event_outlined,
                label: 'Date',
                value: BookingFormat.dateTime(booking.date, lang: lang),
              ),
              DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time',
                value: '${booking.startTime} – ${booking.endTime}',
              ),
              DetailRow(
                icon: Icons.brightness_4_outlined,
                label: 'Shift',
                value: booking.shift.name,
              ),
              DetailRow(
                icon: Icons.place_outlined,
                label: 'Venue',
                value: booking.venue,
              ),
              DetailRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Outdoor',
                value: booking.outdoor ? 'Yes' : 'No',
              ),
              if (booking.coverageHours != null)
                DetailRow(
                  icon: Icons.hourglass_empty_rounded,
                  label: 'Coverage',
                  value: '${booking.coverageHours} h',
                ),
            ],
          ),
        ),
        if (envelope.package != null || booking.customPrice != null)
          DetailSection(
            title: 'Package',
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Name',
                  value: envelope.package?.name ?? 'Custom',
                ),
                if (showPayment)
                  DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Price',
                    value: BookingFormat.money(
                      envelope.package?.basePrice ?? booking.customPrice ?? 0,
                      lang: lang,
                      bnNumerals: lang == 'bn',
                    ),
                    valueColor: AppColors.gold,
                  ),
                if (booking.driveLink != null)
                  DetailRow(
                    icon: Icons.cloud_outlined,
                    label: 'Drive link',
                    value: booking.driveLink,
                    valueColor: AppColors.indigo,
                    onTap: () => _openLink(booking.driveLink!),
                  ),
              ],
            ),
          ),
        if (showPayment)
          PaymentSummaryCard(
            bookingId: booking.id,
            bookingTotal:
                booking.customPrice ?? envelope.package?.basePrice,
          ),
        AssignmentsSection(
          assignments: envelope.assignments,
          currentUserId: currentUserId,
          currentRole: policy.role as UserRole,
          showPayout: showPayment,
          chiefUserId: booking.chiefPhotographerUserId,
        ),
        TaskProgressSection(
          bookingId: booking.id,
          assignments: envelope.assignments,
          taskProgress: envelope.taskProgress,
        ),
        StatusTimeline(entries: envelope.statusHistory),
        ReEditSection(booking: booking, requests: envelope.reEditRequests),
        _InvoiceAction(booking: booking, envelope: envelope, lang: lang),
        if (booking.notes != null && booking.notes!.isNotEmpty)
          DetailSection(
            title: 'Notes',
            child: Text(
              booking.notes!,
              style: TextStyle(
                color: AppColors.film.withValues(alpha: 0.9),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.booking, required this.lang});

  final Booking booking;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusBadge(booking.status, size: BadgeSize.lg),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${BookingFormat.dateTime(booking.date, lang: lang)} · ${_titleCase(booking.shift.name)} shift · ${booking.startTime}–${booking.endTime}',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) => const _CancelReasonDialog(),
  );

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cancel booking',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reason is optional — leave it blank and tap Cancel booking to cancel anyway.',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.85),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
              style: TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                hintStyle: TextStyle(
                  color: AppColors.filmMuted.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: AppColors.line(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.line(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.line(0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Back',
                      style: TextStyle(color: AppColors.filmDim),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onConfirm,
                    child: Text('Cancel booking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm() {
    // Reason is optional: an empty string still confirms the cancel.
    Navigator.of(context).pop(_controller.text.trim());
  }
}

class _ScrollableSlot extends StatelessWidget {
  const _ScrollableSlot({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(child: child),
        ),
      ],
    );
  }
}

enum _DetailMenuAction { cancel, calendar, refresh }

/// Opens Google Calendar's event-template page pre-filled with the
/// booking — works on every device with no API key or OAuth setup; the
/// user just taps Save inside Google Calendar.
void _addToGoogleCalendar(Booking booking) {
  String two(int v) => v.toString().padLeft(2, '0');
  DateTime at(String hhmm, {required String fallback}) {
    final parts = (hhmm.contains(':') ? hhmm : fallback).split(':');
    return DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      int.tryParse(parts[0]) ?? 10,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  final start = at(booking.startTime, fallback: '10:00');
  var end = at(booking.endTime, fallback: '18:00');
  if (!end.isAfter(start)) end = start.add(const Duration(hours: 2));
  String fmt(DateTime d) =>
      '${d.year}${two(d.month)}${two(d.day)}T${two(d.hour)}${two(d.minute)}00';

  final details = [
    if (booking.clientName != null) 'Client: ${booking.clientName}',
    if (booking.clientPhone != null) 'Phone: ${booking.clientPhone}',
    if (booking.notes != null) booking.notes!,
    'Booked via CLICKER PRO',
  ].join('\n');

  final uri = Uri.parse('https://calendar.google.com/calendar/render').replace(
    queryParameters: {
      'action': 'TEMPLATE',
      'text': booking.title,
      'dates': '${fmt(start)}/${fmt(end)}',
      'details': details,
      if (booking.venue != null) 'location': booking.venue!,
    },
  );
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ─────────────────────────────────────────────────────────────────────
// Invoice Action — opens auto-generated invoice bottom sheet
// ─────────────────────────────────────────────────────────────────────

class _InvoiceAction extends ConsumerWidget {
  const _InvoiceAction({
    required this.booking,
    required this.envelope,
    required this.lang,
  });

  final Booking booking;
  final BookingDetailEnvelope envelope;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailSection(
      title: 'Invoice & Share',
      child: Column(
        children: [
          // Client invoice — professional, always carries payment/due.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text('Client Invoice'),
              onPressed: () => _showInvoiceSheet(context, ref, forClient: true),
            ),
          ),
          const SizedBox(height: 10),
          // Share event details — for the team / freelancers; payment is
          // hidden unless the owner opted in on the booking.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.film,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text('Share Event Details'),
              onPressed: () => _showInvoiceSheet(context, ref, forClient: false),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the invoice / share sheet.
  ///
  /// [forClient] = true  → the professional CLIENT INVOICE; payment is shown
  ///   subject to the normal view-payment permission.
  /// [forClient] = false → SHARE EVENT DETAILS for the team / freelancers;
  ///   payment is hidden unless the owner opted in via [showPaymentInShare].
  void _showInvoiceSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool forClient,
  }) {
    final policy = ref.read(bookingsPolicyProvider);
    final showPayment = forClient
        ? shouldShowPayment(
            role: policy.role,
            hidePaymentFromTeam: booking.hidePaymentFromTeam,
            canViewPayments: policy.can(Capability.viewBookingPayments),
          )
        : shouldShowPaymentInShare(
            showPaymentInShare: booking.showPaymentInShare,
          );

    // Resolve real names + phone numbers from the team list so the
    // invoice carries contactable info, not internal user ids.
    final members = ref.read(teamMembersProvider).valueOrNull ?? const [];
    String memberLine(String userId, String roleLabel) {
      final m = members.where((m) => m.userId == userId).firstOrNull;
      if (m == null) return roleLabel;
      final phone = (m.phone ?? '').trim();
      return phone.isEmpty
          ? '${m.fullName} ($roleLabel)'
          : '${m.fullName} ($roleLabel) – $phone';
    }

    final chiefName = _resolveChiefName(members);
    final teamLines = envelope.assignments
        .map((a) => memberLine(a.userId, _titleCase(a.role.name)))
        .toList(growable: false);
    // Team names only (no role suffix) for the simple shared text spec.
    final teamNamesOnly = envelope.assignments
        .map((a) {
          final m = members.where((x) => x.userId == a.userId).firstOrNull;
          return m?.fullName ?? _titleCase(a.role.name);
        })
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
    // "Team num" per Heaven's spec = ONE number (the senior/chief
    // photographer). Fall back to the first team member with a phone.
    final chiefPhone = _resolveChiefPhone(members);
    final teamNo = chiefPhone.isNotEmpty
        ? chiefPhone
        : envelope.assignments.length.toString();

    final clientName =
        envelope.client?.name ?? booking.clientName ?? '—';
    final clientPhone =
        envelope.client?.phone ?? booking.clientPhone ?? '—';

    final total = booking.customPrice ?? envelope.package?.basePrice ?? 0.0;
    final advance = envelope.payments.fold<double>(0, (s, p) => s + p.amount);
    final due = total - advance;

    final dateStr = BookingFormat.dateTime(booking.date, lang: lang);
    String money(double v) =>
        BookingFormat.money(v, lang: lang, bnNumerals: lang == 'bn');

    // Studio identity for the invoice header.
    final me = ref.read(currentUserProvider).valueOrNull;
    final studioName =
        (me?.companyName?.trim().isNotEmpty ?? false)
        ? me!.companyName!.trim()
        : (me?.name ?? 'CLICKER PRO');
    final studioPhone = me?.phone ?? '';
    final studioAddress = me?.studioAddress?.trim() ?? '';

    final brideName = booking.brideName?.trim();
    final groomName = booking.groomName?.trim();

    // Shift label (Day / Night / Full Day).
    final shiftLabel = switch (booking.shift) {
      Shift.day => 'Day',
      Shift.night => 'Night',
      Shift.both => 'Full Day',
    };

    // Document number — both client invoice and shared event details read
    // INV-#### per the requested format.
    final idDigits = booking.id.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceNo = idDigits.isEmpty
        ? 'INV-0001'
        : 'INV-${idDigits.substring(idDigits.length > 4 ? idDigits.length - 4 : 0).padLeft(4, '0')}';

    // Due is shown only when the owner has chosen to (showPayment), per the
    // "Due: (if owner show)" requirement.
    final docLabel = forClient ? 'INVOICE' : 'EVENT DETAILS';

    // Client line prefers bride/groom names for wedding-type events.
    final clientLine =
        (brideName?.isNotEmpty ?? false) || (groomName?.isNotEmpty ?? false)
        ? [brideName, groomName].where((s) => s?.isNotEmpty ?? false).join(' & ')
        : clientName;

    // Package name — shown only when set AND not a custom package.
    final pkgName = envelope.package?.name.trim() ?? '';
    final isCustomPackage =
        pkgName.isEmpty || pkgName.toLowerCase() == 'custom';

    final List<String> lines;
    if (forClient) {
      // Client invoice keeps the full professional layout.
      lines = <String>[
        'Invoice: $invoiceNo',
        'Date: $dateStr',
        'Shift: $shiftLabel',
        'Time: ${booking.startTime} – ${booking.endTime}',
        'Event: ${_titleCase(booking.eventType.name)}',
        'Client: $clientLine',
        'Client no: $clientPhone',
        'Venue: ${booking.venue ?? '—'}',
        if (chiefName != '—') 'Chief: $chiefName',
        if (showPayment) 'Due: ${money(due)}',
      ];
    } else {
      // SHARE EVENT DETAILS — text-only, exact field order Heaven specified.
      // Conditional lines (Outdoor, Package, Payment due) are omitted when
      // they don't apply rather than printed empty.
      lines = <String>[
        'Date: $dateStr',
        'Shift: $shiftLabel',
        'Time: ${booking.startTime} – ${booking.endTime}',
        'Client: $clientLine',
        'Client num: $clientPhone',
        'Location: ${booking.venue ?? '—'}',
        if (booking.outdoor) 'Outdoor: Yes',
        if (!isCustomPackage) 'Package name: $pkgName',
        if (teamNamesOnly.isEmpty)
          'Team: —'
        else
          'Team: ${teamNamesOnly.join(', ')}',
        if (teamNo.isNotEmpty) 'Team num: $teamNo',
        if (showPayment) 'Payment due: ${money(due)}',
      ];
    }
    // Footer carries the studio identity (company name + contact).
    final footer = <String>[
      'Company name: $studioName',
      if (studioPhone.isNotEmpty) 'Contact no: $studioPhone',
      if (studioAddress.isNotEmpty) studioAddress,
    ].join('\n');
    final invoiceText = '${lines.join('\n')}\n\n$footer';

    final data = _InvoiceData(
      docLabel: docLabel,
      studioName: studioName,
      studioPhone: studioPhone,
      studioAddress: studioAddress,
      logoUrl: me?.logoUrl,
      signatureUrl: me?.signatureUrl,
      invoiceNo: invoiceNo,
      dateStr: dateStr,
      timeStr: '${booking.startTime} – ${booking.endTime}',
      eventType: _titleCase(booking.eventType.name),
      brideName: brideName,
      groomName: groomName,
      clientName: clientName,
      clientPhone: clientPhone,
      venue: booking.venue ?? '—',
      chiefName: chiefName,
      // Team is for the SHARED event details only — the client invoice never
      // lists the studio's team / payouts.
      teamLines: forClient ? const <String>[] : teamLines,
      shiftLabel: shiftLabel,
      packageName: envelope.package?.name,
      showPayment: showPayment,
      totalText: money(total),
      advanceText: money(advance),
      dueText: money(due),
      dueIsZero: due <= 0.5,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InvoiceSheet(
        data: data,
        invoiceText: invoiceText,
        bookingTitle: booking.title,
      ),
    );
  }

  String _resolveChiefName(List<TeamMember> members) {
    final chiefId = booking.chiefPhotographerUserId;
    if (chiefId == null) return '—';
    final m = members.where((m) => m.userId == chiefId).firstOrNull;
    if (m != null) {
      final phone = (m.phone ?? '').trim();
      return phone.isEmpty ? m.fullName : '${m.fullName} – $phone';
    }
    // The chief field stores a free-typed name when not picked from team.
    return chiefId;
  }

  /// The single "team number" for shared event details — the senior/chief
  /// photographer's phone, falling back to the first assigned member who has
  /// one. Empty string when no number is available.
  String _resolveChiefPhone(List<TeamMember> members) {
    final chiefId = booking.chiefPhotographerUserId;
    if (chiefId != null) {
      final chief = members.where((m) => m.userId == chiefId).firstOrNull;
      final phone = (chief?.phone ?? '').trim();
      if (phone.isNotEmpty) return phone;
    }
    for (final a in envelope.assignments) {
      final m = members.where((x) => x.userId == a.userId).firstOrNull;
      final phone = (m?.phone ?? '').trim();
      if (phone.isNotEmpty) return phone;
    }
    return '';
  }
}

/// Structured invoice data backing the modern designed invoice template.
class _InvoiceData {
  const _InvoiceData({
    required this.docLabel,
    required this.studioName,
    required this.studioPhone,
    required this.studioAddress,
    required this.logoUrl,
    required this.signatureUrl,
    required this.invoiceNo,
    required this.dateStr,
    required this.shiftLabel,
    required this.timeStr,
    required this.eventType,
    required this.brideName,
    required this.groomName,
    required this.clientName,
    required this.clientPhone,
    required this.venue,
    required this.chiefName,
    required this.teamLines,
    required this.packageName,
    required this.showPayment,
    required this.totalText,
    required this.advanceText,
    required this.dueText,
    required this.dueIsZero,
  });

  final String docLabel;
  final String studioName;
  final String studioPhone;
  final String studioAddress;
  final String? logoUrl;
  final String? signatureUrl;
  final String invoiceNo;
  final String dateStr;
  final String shiftLabel;
  final String timeStr;
  final String eventType;
  final String? brideName;
  final String? groomName;
  final String clientName;
  final String clientPhone;
  final String venue;
  final String chiefName;
  final List<String> teamLines;
  final String? packageName;
  final bool showPayment;
  final String totalText;
  final String advanceText;
  final String dueText;
  final bool dueIsZero;
}

/// Modern, designed invoice template (MOD-14). A branded header band,
/// invoice meta, client + event details, the team list, and a highlighted
/// totals box — shareable via Copy / WhatsApp / Messenger.
class _InvoiceSheet extends StatelessWidget {
  const _InvoiceSheet({
    required this.data,
    required this.invoiceText,
    required this.bookingTitle,
  });

  final _InvoiceData data;
  final String invoiceText;
  final String bookingTitle;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line(0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  _brandHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('BILL TO'),
                        const SizedBox(height: 6),
                        Text(
                          data.clientName,
                          style: TextStyle(
                            color: AppColors.film,
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data.clientPhone != '—')
                          Text(
                            data.clientPhone,
                            style: TextStyle(
                              color: AppColors.filmDim.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 18),
                        _sectionLabel('EVENT DETAILS'),
                        const SizedBox(height: 8),
                        _kv('Event', data.eventType),
                        if (data.brideName?.isNotEmpty ?? false)
                          _kv('Bride', data.brideName!),
                        if (data.groomName?.isNotEmpty ?? false)
                          _kv('Groom', data.groomName!),
                        _kv('Date', data.dateStr),
                        _kv('Shift', data.shiftLabel),
                        _kv('Time', data.timeStr),
                        _kv('Venue', data.venue),
                        if (data.packageName != null)
                          _kv('Package', data.packageName!),
                        if (data.chiefName != '—')
                          _kv('Chief', data.chiefName),
                        if (data.teamLines.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _sectionLabel('TEAM'),
                          const SizedBox(height: 6),
                          for (final line in data.teamLines)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6, right: 8),
                                    child: Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: AppColors.goldConst,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: TextStyle(
                                        color: AppColors.film,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (data.showPayment) ...[
                          const SizedBox(height: 18),
                          _totalsBox(),
                        ],
                        const SizedBox(height: 26),
                        // Signature block — matches the reference invoices'
                        // "YOUR SIGNATURE" line at the bottom-right.
                        _signatureBlock(),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'Generated by ${data.studioName} · CLICKER PRO',
                            style: TextStyle(
                              color: AppColors.filmDim.withValues(alpha: 0.6),
                              fontSize: 10.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _shareBar(context),
          ],
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(gradient: AppColors.orangeGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.studioName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.docLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.studioPhone.isEmpty ? '' : '☎ ${data.studioPhone}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                data.invoiceNo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.film,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _totalRow('Total', data.totalText, Colors.white, false),
          const SizedBox(height: 8),
          _totalRow(
            'Advance Paid',
            data.advanceText,
            AppColors.green,
            false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          _totalRow(
            data.dueIsZero ? 'Due · Fully Paid ✓' : 'Due',
            data.dueText,
            data.dueIsZero ? AppColors.green : AppColors.gold,
            true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color, bool big) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: big ? 14 : 13,
            fontWeight: big ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'Poppins',
            fontSize: big ? 20 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.orange.withValues(alpha: 0.9),
      fontFamily: 'Montserrat',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
    ),
  );

  /// Bottom-right signature block — uses the studio's saved signature image
  /// when present, otherwise a blank signature line, with the studio name.
  Widget _signatureBlock() {
    final hasSig = data.signatureUrl != null && data.signatureUrl!.isNotEmpty;
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasSig)
            SizedBox(
              width: 140,
              height: 48,
              child: Image.network(
                data.signatureUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(height: 48),
              ),
            )
          else
            const SizedBox(height: 30),
          Container(width: 150, height: 1, color: AppColors.line(0.25)),
          const SizedBox(height: 6),
          Text(
            'Authorized Signature',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.8),
              fontFamily: 'Montserrat',
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            data.studioName,
            style: TextStyle(
              color: AppColors.film,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            key,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.8),
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.film,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _shareBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            // Row 1 — share the plain event-details text (client / team).
            Row(
              children: [
                Expanded(
                  child: _ShareButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: invoiceText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Details copied.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShareButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(invoiceText)}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShareButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    color: AppColors.indigo,
                    onTap: () => SharePlus.instance.share(
                      ShareParams(text: invoiceText),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2 — the formal booking invoice PDF: Print (blank signature)
            // or Download (saved signature embedded).
            Row(
              children: [
                Expanded(
                  child: _ShareButton(
                    icon: Icons.print_rounded,
                    label: 'Print',
                    color: AppColors.teal,
                    onTap: () => _exportInvoicePdf(context, forPrint: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShareButton(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    color: AppColors.gold,
                    onTap: () => _exportInvoicePdf(context, forPrint: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the formal booking-invoice PDF from [data]. [forPrint] leaves the
  /// signature blank and opens the print dialog; otherwise the saved
  /// signature is embedded and the file is shared/downloaded.
  Future<void> _exportInvoicePdf(
    BuildContext context, {
    required bool forPrint,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Fetch logo + (download-only) signature as image bytes. Fail-soft:
      // a missing/broken URL just omits that image.
      final logo = await PdfExporter.fetchImageBytes(data.logoUrl);
      final signature = forPrint
          ? null
          : await PdfExporter.fetchImageBytes(data.signatureUrl);

      final detailRows = <PdfRow>[
        PdfRow('Bill To', data.clientName),
        if (data.clientPhone != '—') PdfRow('Client Number', data.clientPhone),
        PdfRow('Event', data.eventType),
        if (data.brideName?.isNotEmpty ?? false)
          PdfRow('Bride', data.brideName!),
        if (data.groomName?.isNotEmpty ?? false)
          PdfRow('Groom', data.groomName!),
        PdfRow('Date', data.dateStr),
        PdfRow('Time', data.timeStr),
        PdfRow('Venue', data.venue),
        if (data.packageName != null) PdfRow('Package', data.packageName!),
        PdfRow('Chief', data.chiefName),
      ];

      final doc = PdfDocumentData(
        documentTitle: 'Invoice',
        fileName: 'invoice_${data.invoiceNo}',
        companyName: data.studioName,
        companyPhone: data.studioPhone,
        companyAddress: data.studioAddress,
        logoBytes: logo,
        signatureBytes: signature,
        subtitle: data.invoiceNo,
        detailRows: detailRows,
        table: data.teamLines.isEmpty
            ? null
            : PdfTable(
                headers: const ['Team'],
                rows: [for (final l in data.teamLines) [l]],
              ),
        summary: data.showPayment
            ? [
                PdfRow('Total', data.totalText),
                PdfRow('Advance', data.advanceText),
                PdfRow('Due', data.dueText, emphasize: true),
              ]
            : const [],
        footnote: 'Generated by ${data.studioName} · CLICKER PRO',
      );

      if (forPrint) {
        await PdfExporter.printDocument(doc);
      } else {
        await PdfExporter.download(doc);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not create the invoice PDF: $e',
            style: TextStyle(color: AppColors.film),
          ),
          backgroundColor: AppColors.voidElevated,
        ),
      );
    }
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: resolvedColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: resolvedColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: resolvedColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: resolvedColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


String _titleCase(String input) {
  if (input.isEmpty) return input;
  // splits camelCase / lower into Title Case ("inProgress" → "In Progress")
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
