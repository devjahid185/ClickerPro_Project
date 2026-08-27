// lib/features/bookings/presentation/web_bookings.dart
//
// Graphy7 — WEB-ONLY bookings screen (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 2).
//
// Rendered ONLY on wide web (BookingListScreen routes here when kIsWeb &&
// width >= 900); the mobile booking list is 100% untouched. Layout follows
// the handoff:
//
//   [All][Pending][Confirmed][Successful][Delivered][Cancelled]
//                                  [🔗 SELF-BOOKING]  [+ New Booking]
//   ┌───────────────────────────┐  ┌───────────────────────────┐
//   │ ☀ Day Shift          (n)  │  │ ☾ Night Shift        (n)  │
//   │ gold-bordered rows →      │  │ ← purple-bordered rows    │
//   └───────────────────────────┘  └───────────────────────────┘
//
// Day rows carry a 3px gold LEFT border and slide RIGHT on hover; night rows
// carry a 3px purple RIGHT border and slide LEFT (mirrored, per the spec).
// Rows show NO status badges (spec decision) — the chips filter instead.
//
// All data comes from the same `bookingListProvider` the mobile list uses —
// no new business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../auth/domain/user_role.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/web_theme.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type_vibe.dart';
import '../domain/shift.dart';

/// A status chip in the filter row — EXACTLY the mobile booking list's tabs
/// (All · Complete · Delivery · Cancel). The old web-only Pending/Confirmed
/// chips were removed for mobile parity (Heaven 2026-07-15: "pending,
/// confirm বাদ যাবে। যা মোবাইলে এপে নেই").
enum _Chip { all, complete, delivered, cancelled }

extension _ChipX on _Chip {
  String get label => switch (this) {
        _Chip.all => 'ALL',
        _Chip.complete => 'COMPLETE',
        _Chip.delivered => 'DELIVERY',
        _Chip.cancelled => 'CANCEL',
      };

  /// The booking statuses this chip keeps — same sets as the mobile tabs.
  Set<BookingStatus> get statuses => switch (this) {
        _Chip.all => const {},
        _Chip.complete => const {
            BookingStatus.inProgress,
            BookingStatus.shotComplete,
            BookingStatus.completed,
          },
        _Chip.delivered => const {BookingStatus.delivered},
        _Chip.cancelled => const {BookingStatus.cancelled},
      };
  Color get color => switch (this) {
        _Chip.all => AppColors.infoTeal,
        _Chip.complete => AppColors.sageData,
        _Chip.delivered => AppColors.sageData,
        _Chip.cancelled => AppColors.red,
      };
}

Color _bookingLifecycleColor(Booking booking) {
  switch (booking.status) {
    case BookingStatus.shotComplete:
    case BookingStatus.delivered:
    case BookingStatus.completed:
      return AppColors.sageData;
    case BookingStatus.cancelled:
      return AppColors.red;
    case BookingStatus.pending:
    case BookingStatus.confirmed:
    case BookingStatus.inProgress:
      return AppColors.infoTeal;
  }
}
/// The wide-web bookings screen. Pure presentation over existing providers.
class WebBookings extends ConsumerStatefulWidget {
  const WebBookings({super.key});

  @override
  ConsumerState<WebBookings> createState() => _WebBookingsState();
}

class _WebBookingsState extends ConsumerState<WebBookings> {
  _Chip _chip = _Chip.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(bookingRepositoryProvider).refreshFromRemote();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the unfiltered stream once; the chip filters client-side so
    // switching is instant and never re-hits the data layer.
    final async = ref.watch(bookingListAllProvider(const BookingFilter()));
    // The dashboard KPI cards (Today / Upcoming / Total / Delivered) preset
    // this shared filter before navigating here — honour it, otherwise the
    // card taps "do nothing" on web (Heaven 2026-07-15).
    final shared = ref.watch(bookingFilterProvider);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          WebEntrance(
            delay: const Duration(milliseconds: 50),
            child: _ChipRow(
              chip: _chip,
              onChip: (c) {
                setState(() => _chip = c);
                if (c == _Chip.all) {
                  ref.read(bookingFilterProvider.notifier).state =
                      const BookingFilter();
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          async.when(
            loading: () => const _LoadingColumns(),
            error: (_, _) => _Message('Could not load bookings.'),
            data: (all) {
              final filtered = _apply(all, shared);
              final day = filtered
                  .where((b) => b.shift != Shift.night)
                  .toList();
              final night = filtered
                  .where((b) => b.shift != Shift.day)
                  .toList();
              return LayoutBuilder(builder: (context, constraints) {
                final narrow = constraints.maxWidth < 760;
                final dayCard = WebEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: _ShiftColumn(night: false, bookings: day),
                );
                final nightCard = WebEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: _ShiftColumn(night: true, bookings: night),
                );
                if (narrow) {
                  return Column(children: [
                    dayCard,
                    const SizedBox(height: 18),
                    nightCard,
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dayCard),
                    const SizedBox(width: 18),
                    Expanded(child: nightCard),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }

  /// Applies the shared dashboard filter (date range + preset statuses),
  /// then the active chip, soonest-first.
  List<Booking> _apply(List<Booking> all, BookingFilter shared) {
    Iterable<Booking> rows = all;
    final from = shared.from;
    final to = shared.to;
    if (from != null) {
      rows = rows.where((b) => !b.date.isBefore(from));
    }
    if (to != null) {
      rows = rows.where((b) => b.date.isBefore(to));
    }
    final wanted = _chip.statuses;
    final out = rows.where((b) {
      if (wanted.isNotEmpty) return wanted.contains(b.status);
      if (shared.statuses.isNotEmpty) return shared.statuses.contains(b.status);
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return out;
  }
}

// ─────────────────────────────────────────────────────────── CHIP ROW
class _ChipRow extends ConsumerWidget {
  const _ChipRow({required this.chip, required this.onChip});
  final _Chip chip;
  final ValueChanged<_Chip> onChip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    // Mobile parity: a Freelancer's list has no Delivery tab (delivery is
    // Owner work), no self-booking queue and no full studio booking form.
    final chips = policy.role == UserRole.freelancer
        ? _Chip.values.where((c) => c != _Chip.delivered)
        : _Chip.values;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in chips)
          _StatusChip(
            label: c.label,
            active: c == chip,
            color: c.color,
            onTap: () => onChip(c),
          ),
        // Right-aligned actions ride the same wrap on narrow widths.
        if (policy.can(Capability.approvePublicBooking))
          _SelfBookingChip(
            onTap: () => Navigator.of(context)
                .pushNamed(RouteNames.pendingPublicBookings),
          ),
        if (policy.can(Capability.createOwnBooking))
          _NewBookingPill(
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.bookingNew),
          ),
      ],
    );
  }
}

/// Mono uppercase status pill — active = orange fill, cream text.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color
              : hovering
                  ? color.withValues(alpha: 0.12)
                  : WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
            color: active
                ? color
                : hovering
                    ? color.withValues(alpha: 0.28)
                    : WebTheme.hairline,
          ),
        ),
        child: Text(
          label,
          style: WebTheme.label(
            size: 10,
            tracking: 0.08,
            color: active ? WebTheme.chromeInk : WebTheme.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// 🔗 SELF-BOOKING — orange-tint chip; fills orange on hover (handoff).
class _SelfBookingChip extends StatelessWidget {
  const _SelfBookingChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orange : WebTheme.orangeTint,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
              color:
                  hovering ? WebTheme.orange : WebTheme.orangeTintBorder),
        ),
        child: Text(
          '🔗 SELF-BOOKING',
          style: WebTheme.label(
            size: 10,
            tracking: 0.08,
            color: hovering ? WebTheme.chromeInk : WebTheme.orangeDeep,
          ),
        ),
      ),
    );
  }
}

/// "+ New Booking" — solid orange pill with glow.
class _NewBookingPill extends StatelessWidget {
  const _NewBookingPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        transform:
            Matrix4.translationValues(0, hovering ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orangeDark : WebTheme.orange,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          boxShadow: WebTheme.buttonGlow,
        ),
        child: Text(
          '+ New Booking',
          style: WebTheme.bodyStyle(
            size: 13,
            weight: FontWeight.w700,
            color: WebTheme.chromeInk,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────── SHIFT COLUMNS
/// One of the two mirrored cards: ☀ Day (gold) or ☾ Night (purple).
class _ShiftColumn extends StatelessWidget {
  const _ShiftColumn({required this.night, required this.bookings});
  final bool night;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final accent = night ? WebTheme.night : WebTheme.amber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with the 2px accent bottom border.
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: accent, width: 2),
              ),
            ),
            child: Row(
              children: [
                Text(night ? '☾' : '☀',
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Text(night ? 'Night Shift' : 'Day Shift',
                    style: WebTheme.displayStyle(size: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: night
                        ? WebTheme.nightTint
                        : WebTheme.orangeTint,
                    borderRadius: BorderRadius.circular(WebTheme.rFull),
                    border: Border.all(
                        color: night
                            ? WebTheme.nightTintBorder
                            : WebTheme.orangeTintBorder),
                  ),
                  child: Text(
                    '${bookings.length}',
                    style: TextStyle(
                      fontFamily: WebTheme.mono,
                      fontSize: 10,
                      color: night
                          ? WebTheme.nightText
                          : WebTheme.orangeDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                night ? 'No night-shift bookings.' : 'No day-shift bookings.',
                textAlign: TextAlign.center,
                style:
                    WebTheme.bodyStyle(size: 12, color: WebTheme.inkMuted),
              ),
            )
          else
            for (var i = 0; i < bookings.length; i++) ...[
              if (i != 0) const SizedBox(height: 8),
              WebEntrance(
                delay: Duration(milliseconds: (50 * i).clamp(0, 500)),
                offset: 6,
                child: _ShiftRow(booking: bookings[i], night: night),
              ),
            ],
        ],
      ),
    );
  }
}

/// One booking row: 40px date block · client + "type · area" · › chevron.
/// Day rows border-left gold, hover slides +4px; night rows border-right
/// purple, hover slides −4px (mirrored).
class _ShiftRow extends StatefulWidget {
  const _ShiftRow({required this.booking, required this.night});
  final Booking booking;
  final bool night;

  @override
  State<_ShiftRow> createState() => _ShiftRowState();
}

class _ShiftRowState extends State<_ShiftRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final night = widget.night;
    final accent = _bookingLifecycleColor(b);
    final client = (b.clientName?.trim().isNotEmpty ?? false)
        ? b.clientName!.trim()
        : b.title;
    final area = b.venue?.trim().isNotEmpty == true ? b.venue!.trim() : null;
    final sub =
        area == null ? b.eventType.vibe.label : '${b.eventType.vibe.label} · $area';

    final noMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dx = _hover && !noMotion ? (night ? -4.0 : 4.0) : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .pushNamed(RouteNames.bookingDetail, arguments: b.id),
        child: AnimatedContainer(
          duration: noMotion ? Duration.zero : WebTheme.base,
          curve: WebTheme.ease,
          transform: Matrix4.translationValues(dx, 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: _hover ? 0.18 : 0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: night
                  ? const BorderSide(color: WebTheme.innerLine)
                  : BorderSide(color: accent, width: 3),
              right: night
                  ? BorderSide(color: accent, width: 3)
                  : const BorderSide(color: WebTheme.innerLine),
              top: const BorderSide(color: WebTheme.innerLine),
              bottom: const BorderSide(color: WebTheme.innerLine),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text('${b.date.day}',
                        style: WebTheme.displayStyle(
                            size: 17,
                            weight: FontWeight.w800,
                            height: 1)),
                    Text(
                      DateFormat('MMM').format(b.date).toUpperCase(),
                      style: WebTheme.label(
                          size: 7.5,
                          color: WebTheme.inkMuted,
                          tracking: 0.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                            size: 13, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTheme.bodyStyle(
                            size: 11, color: WebTheme.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('›',
                  style: TextStyle(
                      fontSize: 14, color: WebTheme.inkFaint, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _LoadingColumns extends StatelessWidget {
  const _LoadingColumns();

  @override
  Widget build(BuildContext context) {
    Widget card() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(WebTheme.rCard),
            border: Border.all(color: WebTheme.hairline),
          ),
          child: Column(
            children: List.generate(
              4,
              (i) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: WebShimmer(height: 46, borderRadius: 12),
              ),
            ),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card()),
        const SizedBox(width: 18),
        Expanded(child: card()),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Center(
        child: Text(
          message,
          style: WebTheme.bodyStyle(size: 13, color: WebTheme.inkMuted),
        ),
      ),
    );
  }
}
