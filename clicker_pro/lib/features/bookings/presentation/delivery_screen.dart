// lib/features/bookings/presentation/delivery_screen.dart
//
// Delivery pipeline — what happens to an event AFTER the shoot.
//
// The sidebar "Delivery System" used to dump the user on the generic
// booking list. Per Heaven's feedback (2026-07) this screen shows the
// real post-shoot pipeline instead:
//
//   IN EDITING (shotComplete)  → client is waiting; overdue ages are
//                                highlighted so nothing rots in the queue
//   DELIVERED  (delivered)     → handed over, awaiting final close
//
// Row actions: advance the status (Deliver / Complete) and a WhatsApp
// shortcut to tell the client their photos/videos are ready.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/booking_format.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../whatsapp/data/whatsapp_service.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import 'booking_detail_screen.dart';

/// Filter for everything currently in the post-shoot pipeline.
const _pipelineFilter = BookingFilter(
  statuses: {BookingStatus.shotComplete, BookingStatus.delivered},
);

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingListAllProvider(_pipelineFilter));

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Delivery',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load the delivery pipeline.\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
        ),
        data: (bookings) {
          final editing =
              bookings
                  .where((b) => b.status == BookingStatus.shotComplete)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date)); // oldest first
          final delivered =
              bookings
                  .where((b) => b.status == BookingStatus.delivered)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          if (editing.isEmpty && delivered.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.local_shipping_outlined,
                message:
                    'Nothing in the pipeline.\nEvents appear here after the '
                    'shoot is marked complete.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SummaryStrip(
                editingCount: editing.length,
                deliveredCount: delivered.length,
              ),
              if (editing.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _SectionHeader(
                  label: 'IN EDITING — CLIENT WAITING',
                  icon: Icons.movie_edit,
                ),
                const SizedBox(height: 8),
                ...editing.map(
                  (b) => _DeliveryRow(
                    booking: b,
                    actionLabel: 'Deliver',
                    actionIcon: Icons.local_shipping_outlined,
                    nextStatus: BookingStatus.delivered,
                  ),
                ),
              ],
              if (delivered.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _SectionHeader(
                  label: 'DELIVERED — AWAITING CLOSE',
                  icon: Icons.inventory_outlined,
                ),
                const SizedBox(height: 8),
                ...delivered.map(
                  (b) => _DeliveryRow(
                    booking: b,
                    actionLabel: 'Complete',
                    actionIcon: Icons.check_circle_outline,
                    nextStatus: BookingStatus.completed,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.editingCount,
    required this.deliveredCount,
  });

  final int editingCount;
  final int deliveredCount;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, Color colour) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colour,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('IN EDITING', '$editingCount', AppColors.orange),
        const SizedBox(width: 10),
        cell('DELIVERED', '$deliveredCount', AppColors.green),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmDim,
            fontFamily: AppText.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _DeliveryRow extends ConsumerStatefulWidget {
  const _DeliveryRow({
    required this.booking,
    required this.actionLabel,
    required this.actionIcon,
    required this.nextStatus,
  });

  final Booking booking;
  final String actionLabel;
  final IconData actionIcon;
  final BookingStatus nextStatus;

  @override
  ConsumerState<_DeliveryRow> createState() => _DeliveryRowState();
}

class _DeliveryRowState extends ConsumerState<_DeliveryRow> {
  bool _busy = false;

  /// Days the client has been waiting since the shoot date.
  int get _waitingDays =>
      DateTime.now().difference(widget.booking.date).inDays;

  Color get _ageColour {
    if (widget.booking.status != BookingStatus.shotComplete) {
      return AppColors.filmMuted;
    }
    if (_waitingDays > 30) return AppColors.red;
    if (_waitingDays > 14) return AppColors.gold;
    return AppColors.filmMuted;
  }

  Future<void> _advance() async {
    final booking = widget.booking;
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(statusRepositoryProvider)
          .transition(
            bookingId: booking.id,
            expectedFrom: booking.status,
            to: widget.nextStatus,
            changedByUserId: user.id,
            policy: ref.read(bookingsPolicyProvider),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.nextStatus == BookingStatus.delivered
                ? 'Marked delivered — ${booking.title}'
                : 'Completed — ${booking.title}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _notifyClient() async {
    final booking = widget.booking;
    final phone = booking.clientPhone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No client phone on this booking.')),
      );
      return;
    }
    final name = booking.clientName ?? '';
    final message = booking.status == BookingStatus.shotComplete
        ? 'Hi $name, your photos/videos from "${booking.title}" are being '
              'edited and will be ready soon. Thank you for your patience!'
        : 'Hi $name, your photos/videos from "${booking.title}" are ready! '
              'Please contact us to collect them. Thank you!';
    final ok = await WhatsAppService.openChat(phone: phone, message: message);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final waiting = _waitingDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BookingDetailScreen(bookingId: booking.id),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if ((booking.clientName ?? '').isNotEmpty)
                            booking.clientName!,
                          BookingFormat.dateTime(booking.date, lang: 'en'),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.filmDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _ageColour.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ageColour.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    waiting <= 0 ? 'Today' : '$waiting d',
                    style: TextStyle(
                      color: _ageColour,
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _advance,
                  icon: _busy
                      ? const LensLoader(size: 14)
                      : Icon(widget.actionIcon, size: 16),
                  label: Text(widget.actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _notifyClient,
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
