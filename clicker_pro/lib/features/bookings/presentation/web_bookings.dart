// lib/features/bookings/presentation/web_bookings.dart
//
// Graphy7 — WEB-ONLY bookings screen (Graphy7 Design).
//
// A desktop bookings table, rendered ONLY on wide web. The mobile booking list
// body is 100% untouched (BookingListScreen routes here only when
// kIsWeb && width >= 900). Ported from the design source's "Bookings" screen:
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │  Header (title + count)                       New Booking (⊕) │
//   ├──────────────────────────────────────────────────────────────┤
//   │  [All][Confirmed][Pending][Delivered][Cancelled]     search   │
//   ├──────────────────────────────────────────────────────────────┤
//   │  CLIENT · EVENT · DATE · AMOUNT · STATUS                      │
//   │  ● Client name / email     Wedding   12 Jul  ৳85,000  [pill]  │
//   │  …                                                            │
//   └──────────────────────────────────────────────────────────────┘
//
// All data comes from the same `bookingListProvider` the mobile list uses —
// no new business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/booking_format.dart';
import '../../../core/format/currency.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type_vibe.dart';

/// A status tab in the design-source filter row.
enum _Tab { all, confirmed, pending, delivered, cancelled }

extension _TabX on _Tab {
  String get label => switch (this) {
        _Tab.all => 'All',
        _Tab.confirmed => 'Confirmed',
        _Tab.pending => 'Pending',
        _Tab.delivered => 'Delivered',
        _Tab.cancelled => 'Cancelled',
      };

  /// The booking statuses this tab keeps. `all` keeps everything.
  Set<BookingStatus> get statuses => switch (this) {
        _Tab.all => const {},
        _Tab.confirmed => const {BookingStatus.confirmed},
        _Tab.pending => const {BookingStatus.pending},
        _Tab.delivered => const {
            BookingStatus.delivered,
            BookingStatus.completed,
          },
        _Tab.cancelled => const {BookingStatus.cancelled},
      };
}

/// The wide-web bookings table. Pure presentation over the existing providers.
class WebBookings extends ConsumerStatefulWidget {
  const WebBookings({super.key});

  @override
  ConsumerState<WebBookings> createState() => _WebBookingsState();
}

class _WebBookingsState extends ConsumerState<WebBookings> {
  _Tab _tab = _Tab.all;
  String _search = '';

  /// Max content width keeps the table from stretching on ultra-wide monitors.
  static const double _maxContentWidth = 1320;

  @override
  Widget build(BuildContext context) {
    // Watch the unfiltered stream once; tab + search filter client-side so
    // switching tabs is instant and never re-hits the data layer.
    final async = ref.watch(bookingListProvider(const BookingFilter()));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(child: _Header(total: async.value?.length)),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: _FilterBar(
                tab: _tab,
                search: _search,
                onTab: (t) => setState(() => _tab = t),
                onSearch: (s) => setState(() => _search = s),
              ),
            ),
            const SizedBox(height: WebTheme.sp4),
            WebEntrance(
              delay: const Duration(milliseconds: 110),
              child: async.when(
                loading: () => const _TableCard(child: _TableSkeleton()),
                error: (_, _) => const _TableCard(
                  child: _TableMessage(message: 'Could not load bookings.'),
                ),
                data: (all) {
                  final rows = _apply(all);
                  return _TableCard(
                    child: rows.isEmpty
                        ? const _TableMessage(
                            message: 'No bookings match this filter.')
                        : _BookingsTable(rows: rows, total: all.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies the active tab + search to the full list, newest-first.
  List<Booking> _apply(List<Booking> all) {
    final wanted = _tab.statuses;
    final q = _search.trim().toLowerCase();
    final out = all.where((b) {
      if (wanted.isNotEmpty && !wanted.contains(b.status)) return false;
      if (q.isEmpty) return true;
      final name = (b.clientName ?? b.title).toLowerCase();
      return name.contains(q) || b.title.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return out;
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({this.total});
  final int? total;

  @override
  Widget build(BuildContext context) {
    final count = total == null ? '—' : '$total';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: WebTheme.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count total · sorted by date',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: WebTheme.sp4),
        _NewBookingCta(
          onTap: () => Navigator.of(context).pushNamed(RouteNames.bookingNew),
        ),
      ],
    );
  }
}

class _NewBookingCta extends StatelessWidget {
  const _NewBookingCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rButton,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: WebTheme.orange,
          borderRadius: BorderRadius.circular(WebTheme.rButton),
          boxShadow: [
            BoxShadow(
              color: WebTheme.orange.withValues(alpha: 0.42),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'New Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── FILTER BAR
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.tab,
    required this.search,
    required this.onTab,
    required this.onSearch,
  });

  final _Tab tab;
  final String search;
  final ValueChanged<_Tab> onTab;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Segmented status tabs — active = orange fill (design source).
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(WebTheme.rButton),
            border: Border.all(color: WebTheme.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in _Tab.values)
                _TabChip(
                  label: t.label,
                  active: t == tab,
                  onTap: () => onTab(t),
                ),
            ],
          ),
        ),
        const Spacer(),
        _SearchBox(value: search, onChanged: onSearch),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverHighlight(
      borderRadius: WebTheme.rChip,
      onTap: onTap,
      builder: (context, hovering) {
        return AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? WebTheme.orange
                : hovering
                    ? WebTheme.sageTint
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(WebTheme.rChip),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : WebTheme.inkMuted,
            ),
          ),
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WebTheme.ink,
        ),
        cursorColor: WebTheme.orange,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search client…',
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: WebTheme.inkFaint,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: WebTheme.inkFaint),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          filled: true,
          fillColor: WebTheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WebTheme.rButton),
            borderSide: const BorderSide(color: WebTheme.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WebTheme.rButton),
            borderSide: const BorderSide(color: WebTheme.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WebTheme.rButton),
            borderSide: const BorderSide(color: WebTheme.orange, width: 1.4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── TABLE CARD
class _TableCard extends StatelessWidget {
  const _TableCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({required this.rows, required this.total});
  final List<Booking> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TableHeaderRow(),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: WebTheme.hairline),
          _BookingRow(booking: rows[i]),
        ],
        _TableFooter(shown: rows.length, total: total),
      ],
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: const BoxDecoration(
        color: WebTheme.pageBgDeep,
        border: Border(bottom: BorderSide(color: WebTheme.hairline)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 5, child: _HeaderLabel('CLIENT')),
          Expanded(flex: 3, child: _HeaderLabel('EVENT')),
          Expanded(flex: 2, child: _HeaderLabel('DATE')),
          Expanded(
            flex: 2,
            child: _HeaderLabel('AMOUNT', align: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: _HeaderLabel('STATUS', align: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontFamily: WebTheme.mono,
        fontSize: 9.5,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w500,
        color: WebTheme.inkFaint,
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});
  final Booking booking;

  String _statusLabel(String raw) {
    final spaced = raw.replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]}');
    final t = spaced.trim();
    return t.isEmpty ? raw : '${t[0].toUpperCase()}${t.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final vibe = booking.eventType.vibe;
    final client = (booking.clientName?.trim().isNotEmpty ?? false)
        ? booking.clientName!.trim()
        : booking.title;
    final sub = booking.clientPhone?.trim().isNotEmpty ?? false
        ? booking.clientPhone!.trim()
        : BookingFormat.clockTime(booking.startTime);
    final dateStr = DateFormat('d MMM yyyy').format(booking.date);
    final statusColor = WebTheme.statusColor(booking.status.name);
    final price = booking.customPrice;

    return WebHoverHighlight(
      borderRadius: 0,
      onTap: () => Navigator.of(context)
          .pushNamed(RouteNames.bookingDetail, arguments: booking.id),
      builder: (context, hovering) {
        return AnimatedContainer(
          duration: WebTheme.fast,
          curve: WebTheme.ease,
          color: hovering ? WebTheme.sageTintSoft : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          child: Row(
            children: [
              // Client (avatar + name + phone/time).
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: vibe.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(WebTheme.rChip),
                      ),
                      child: Icon(vibe.icon, color: vibe.color, size: 19),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: WebTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: WebTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Event type.
              Expanded(
                flex: 3,
                child: Text(
                  vibe.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkSoft,
                  ),
                ),
              ),
              // Date.
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkSoft,
                  ),
                ),
              ),
              // Amount (right-aligned).
              Expanded(
                flex: 2,
                child: Text(
                  price == null ? '—' : _formatBdt((price * 100).round()),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Status pill (right-aligned).
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WebTheme.rFull),
                    ),
                    child: Text(
                      _statusLabel(booking.status.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.shown, required this.total});
  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        color: WebTheme.pageBgDeep,
        border: Border(top: BorderSide(color: WebTheme.hairline)),
      ),
      child: Text(
        shown == total
            ? 'Showing all $total bookings'
            : 'Showing $shown of $total bookings',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: WebTheme.inkMuted,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                WebShimmer(width: 36, height: 36, borderRadius: WebTheme.rChip),
                SizedBox(width: 12),
                Expanded(child: WebShimmer(height: 14, borderRadius: 6)),
                SizedBox(width: 40),
                WebShimmer(width: 70, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableMessage extends StatelessWidget {
  const _TableMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: const Icon(Icons.event_busy_rounded,
                  color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
/// Compact active-currency formatter (paisa → symbol, South-Asian grouping).
/// Mirrors the web dashboard so totals read identically across web surfaces.
String _formatBdt(int minor) {
  final taka = (minor / 100).round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}
