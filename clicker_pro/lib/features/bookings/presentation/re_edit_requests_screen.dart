// lib/features/bookings/presentation/re_edit_requests_screen.dart
//
// Standalone screen listing all re-edit requests across every booking.
// Groups by status (open vs. closed) and shows overdue badges.
// Tapping a row navigates to the parent booking detail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/route_names.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/booking_providers.dart';
import '../domain/re_edit_request.dart';
import '../domain/re_edit_status.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final allReEditRequestsProvider = FutureProvider<List<ReEditRequest>>(
  (ref) => ref.read(reEditRepositoryProvider).listAll(),
);

// ─── Screen ──────────────────────────────────────────────────────────────────

class ReEditRequestsScreen extends ConsumerWidget {
  const ReEditRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allReEditRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Re-edit Requests',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () async => ref.invalidate(allReEditRequestsProvider),
        child: async.when(
          loading: () =>
              const Center(child: LensLoader()),
          error: (_, _) => ErrorState(
            message: 'Failed to load re-edit requests',
            onRetry: () => ref.invalidate(allReEditRequestsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                message: 'No re-edit requests yet',
                icon: Icons.edit_note_outlined,
              );
            }
            final open = items
                .where((r) =>
                    r.status == ReEditStatus.pending ||
                    r.status == ReEditStatus.inProgress)
                .toList()
              ..sort((a, b) => a.deadline.compareTo(b.deadline));
            final closed = items
                .where((r) =>
                    r.status == ReEditStatus.done ||
                    r.status == ReEditStatus.rejected)
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (open.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Open',
                    count: open.length,
                    color: AppColors.orange,
                  ),
                  const SizedBox(height: 8),
                  for (final r in open) _ReEditCard(request: r),
                  const SizedBox(height: 16),
                ],
                if (closed.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Closed',
                    count: closed.length,
                    color: AppColors.filmDim,
                  ),
                  const SizedBox(height: 8),
                  for (final r in closed) _ReEditCard(request: r),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card ────────────────────────────────────────────────────────────────────

class _ReEditCard extends StatelessWidget {
  const _ReEditCard({required this.request});
  final ReEditRequest request;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(request.status);
    final dateText = DateFormat.yMMMd().format(request.deadline);
    final isClosed = request.status == ReEditStatus.done ||
        request.status == ReEditStatus.rejected;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        RouteNames.bookingDetail,
        arguments: request.bookingId,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: Text(
                'R${request.round}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPill(status: request.status, tone: tone),
                      if (request.isOverdue) ...[
                        const SizedBox(width: 6),
                        _OverdueBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 13,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isClosed ? 'Deadline was $dateText' : 'Due $dateText',
                        style: TextStyle(
                          color: AppColors.filmMuted.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if ((request.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.film.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.filmMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.tone});
  final ReEditStatus status;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ReEditStatus.pending => 'PENDING',
      ReEditStatus.inProgress => 'IN PROGRESS',
      ReEditStatus.done => 'DONE',
      ReEditStatus.rejected => 'REJECTED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone.fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'OVERDUE',
        style: TextStyle(
          color: AppColors.red,
          fontSize: 9,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tone {
  const _Tone({required this.bg, required this.fg, required this.border});
  final Color bg;
  final Color fg;
  final Color border;
}

_Tone _toneFor(ReEditStatus s) => switch (s) {
      ReEditStatus.pending => _Tone(
          bg: AppColors.indigo.withValues(alpha: 0.18),
          fg: AppColors.indigo,
          border: AppColors.indigo.withValues(alpha: 0.45),
        ),
      ReEditStatus.inProgress => _Tone(
          bg: AppColors.orange.withValues(alpha: 0.18),
          fg: AppColors.orange,
          border: AppColors.orange.withValues(alpha: 0.45),
        ),
      ReEditStatus.done => _Tone(
          bg: AppColors.green.withValues(alpha: 0.18),
          fg: AppColors.green,
          border: AppColors.green.withValues(alpha: 0.45),
        ),
      ReEditStatus.rejected => _Tone(
          bg: AppColors.red.withValues(alpha: 0.18),
          fg: AppColors.red,
          border: AppColors.red.withValues(alpha: 0.45),
        ),
    };
