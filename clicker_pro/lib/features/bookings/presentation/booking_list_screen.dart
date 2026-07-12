// lib/features/bookings/presentation/booking_list_screen.dart
//
// First end-to-end booking surface. Subscribes to `bookingListProvider`
// keyed by the active filter, renders one of the four shared async
// states (LensLoader / EmptyState / ErrorState / content), shows the
// shared OfflineBanner, and exposes a "+" FAB that — for now — surfaces
// a non-blocking SnackBar; the New/Edit screen lands in a later wave.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Booking List" + "Visual Design Notes". Validates Requirements
// 1.1, 1.2, 1.9, 1.10, 1.12, 1.13, 1.14, 11.3.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/booking_format.dart';
import '../../../core/role/capability.dart';
import '../../../core/navigation/route_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/web_shell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

import '../../auth/domain/user_role.dart';
import '../../freelancer/application/fl_earning_providers.dart';
import '../../profile/application/profile_controllers.dart';
import '../../public_booking/application/public_booking_providers.dart';
import '../../settings/application/language_controller.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type_vibe.dart';
import '../domain/shift.dart';
import 'web_bookings.dart';

enum _StatusChip { all, complete, delivered, cancelled }

enum _DateRangePreset { any, today, week, month, lastMonth }

/// Which edge a booking card's shift accent sits on. Day cards accent the
/// left edge, Night cards the right — matching the .dc.html "Booking List".
enum _AccentSide { left, right }

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  // Captured in initState so `dispose()` can reset the shared filter without
  // touching `ref` — `ref` is invalid once the element is being finalized
  // (e.g. when the whole tree is torn down), which throws "Cannot use ref
  // after the widget was disposed". The StateController itself stays alive.
  late final StateController<BookingFilter> _filterController;

  @override
  void initState() {
    super.initState();
    _filterController = ref.read(bookingFilterProvider.notifier);
    // Pull fresh self-booking requests so the pending badge is accurate
    // as soon as the list opens (fail-soft inside refreshPending).
    Future.microtask(
      () => ref.read(publicBookingRepositoryProvider).refreshPending(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    // `bookingFilterProvider` is shared app-wide so a dashboard card (Today /
    // Upcoming / Delivered / Cancelled) can preset it before navigating here.
    // Left in place after the screen closes, it silently scoped the NEXT
    // visit to whatever the last card tap set — a newly created booking
    // outside that date/status window then looked like it "didn't save"
    // until the filter was noticed and cleared by hand. Reset on the way
    // out so every fresh entry starts unfiltered unless a card sets it again.
    _filterController.state = const BookingFilter();
    super.dispose();
  }

  _StatusChip get _activeChip {
    final statuses = ref.read(bookingFilterProvider).statuses;
    if (statuses.isEmpty) return _StatusChip.all;
    // Resolve the active chip by matching the filter's status set against each
    // chip's status set — the exact inverse of [_statusesForChip]. This must
    // cover EVERY chip (including the multi-status `successful` and the
    // single-status `cancelled`); missing one made that tab fall back to
    // "all", which then hid its own rows (cancelled never rendered).
    for (final chip in _StatusChip.values) {
      if (chip == _StatusChip.all) continue;
      if (_setEquals(statuses, _statusesForChip(chip))) return chip;
    }
    return _StatusChip.all;
  }

  static bool _setEquals(Set<BookingStatus> a, Set<BookingStatus> b) =>
      a.length == b.length && a.containsAll(b);

  /// Date with the time stripped — so same-day events group together
  /// regardless of their shift start time.
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Day shift sorts before Night within the same date; Both counts as Day.
  static int _shiftRank(Shift s) => s == Shift.night ? 1 : 0;

  Set<BookingStatus> _statusesForChip(_StatusChip chip) {
    switch (chip) {
      case _StatusChip.all:
        return {};
      // "Complete" = the shoot is done but not yet handed over: covers the
      // whole in-progress → shot-complete → completed run. Delivered has its
      // own tab, so it is intentionally excluded here.
      case _StatusChip.complete:
        return {
          BookingStatus.inProgress,
          BookingStatus.shotComplete,
          BookingStatus.completed,
        };
      case _StatusChip.delivered:
        return {BookingStatus.delivered};
      case _StatusChip.cancelled:
        return {BookingStatus.cancelled};
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        filter: ref.read(bookingFilterProvider),
        onApply: (filter) {
          ref.read(bookingFilterProvider.notifier).state = filter;
        },
      ),
    );
  }

  /// Shares the studio's public self-booking web link — the client
  /// fills the form themselves and the booking lands as PENDING.
  Future<void> _shareBookingLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(publicBookingRepositoryProvider);
      final issued = await repo.issueToken(
        policy: ref.read(bookingsPolicyProvider),
      );
      // An empty token means the account has no public_booking_token yet
      // (older accounts) — sharing would produce a dead ".../book/" link.
      // Surface a clear message instead of a broken link.
      if (issued.token.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Your booking link isn\'t ready yet. Please sign out and back in, '
              'then try again.',
            ),
          ),
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Fill in your details at this link to book our studio:\n${issued.url}',
          subject: 'Booking link',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not fetch the link — please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(bookingFilterProvider);
    // Use the UNPAGINATED stream. The old paginated provider re-keyed its
    // stream every time infinite-scroll bumped the page cursor, which rebuilt
    // the whole scroll view and snapped the position back — on the "Total"
    // card (every booking, well past one 20-row page) that made the list feel
    // un-scrollable, while "Delivery" (a short list, never past page 0) stayed
    // smooth. Reading the full set renders one stable list that scrolls
    // normally. (Aggregate screens already read this same provider.)
    final listAsync = ref.watch(bookingListAllProvider(filter));
    final policy = ref.watch(bookingsPolicyProvider);
    final loc = AppLocalizations.of(context);
    final bookings = listAsync.valueOrNull;
    final totalCount = bookings?.length ?? 0;

    // On wide web the WebNavShell owns the chrome (sidebar + top bar); render
    // the dedicated desktop bookings table instead of the mobile body. Mobile
    // and narrow web keep the original layout 100% unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: WebBookings(),
      );
    }

    return Scaffold(
      // WEB readability fix: the screen previously used `voidBlack` which on
      // web resolves to a dark-cream (#F4EBDD) — combined with the glass cards
      // it made text hard to read ("লেখা বুঝা যায় না"). On web we use a clean
      // transparent scaffold so the WebShell's light backdrop shows through and
      // the dark `film` text sits on a bright surface. Mobile is untouched.
      backgroundColor: kIsWeb ? Colors.transparent : AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          loc.bookings_title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: loc.bookings_calendar,
            icon: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.gold,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.calendar),
          ),
          IconButton(
            tooltip: 'Waitlist',
            icon: Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.gold,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.waitlist),
          ),
          if (policy.can(Capability.approvePublicBooking)) ...[
            IconButton(
              tooltip: 'Share booking link',
              icon: Icon(Icons.share_outlined, color: AppColors.teal),
              onPressed: () => _shareBookingLink(context),
            ),
            IconButton(
              tooltip: 'Pending requests',
              icon: Badge(
                isLabelVisible:
                    (ref.watch(pendingPublicBookingsProvider).valueOrNull ??
                            const [])
                        .isNotEmpty,
                label: Text(
                  '${(ref.watch(pendingPublicBookingsProvider).valueOrNull ?? const []).length}',
                ),
                backgroundColor: AppColors.orange,
                textColor: Colors.white,
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.gold,
                ),
              ),
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(RouteNames.pendingPublicBookings),
            ),
          ],
          if (listAsync.hasValue)
            Center(
              // Design (.dc.html "Booking List"): count badge sits inline next
              // to the title — soft orange tint fill (#FBEBDE) with the darker
              // brand-orange text (#B84E0A), in the mono label face.
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalCount',
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    color: AppColors.primary700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Filter',
            icon: Icon(
              Icons.tune_rounded,
              color: filter.isEmpty ? AppColors.filmDim : AppColors.teal,
            ),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            tooltip: 'Search',
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? AppColors.teal : AppColors.filmDim,
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                ref.read(bookingFilterProvider.notifier).state = ref
                    .read(bookingFilterProvider)
                    .copyWith(clearSearch: true);
              }
            }),
          ),
        ],
      ),
      floatingActionButton: policy.can(Capability.createBooking)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                loc.bookings_new_booking,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.bookingNew),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            if (_showSearch)
              _SearchBar(
                controller: _searchController,
                onChanged: (value) {
                  // Searching means "find it anywhere" — drop any date range
                  // or status scope a dashboard card tap (Today/Upcoming/
                  // Delivered) left on the shared filter. Keeping them made
                  // search silently return only today's events.
                  ref.read(bookingFilterProvider.notifier).state = ref
                      .read(bookingFilterProvider)
                      .copyWith(
                        search: value.isEmpty ? null : value,
                        clearSearch: value.isEmpty,
                        clearFrom: value.isNotEmpty,
                        clearTo: value.isNotEmpty,
                        statuses: value.isNotEmpty
                            ? const <BookingStatus>{}
                            : null,
                      );
                },
              ),
            _StatusChips(
              selected: _activeChip,
              onSelected: (chip) {
                ref.read(bookingFilterProvider.notifier).state = ref
                    .read(bookingFilterProvider)
                    .copyWith(statuses: _statusesForChip(chip));
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.teal,
                backgroundColor: AppColors.voidElevated,
                onRefresh: () async {
                  await ref.read(bookingRepositoryProvider).refreshFromRemote();
                },
                child: listAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: LensLoader(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: ErrorState(
                        message: loc.bookings_could_not_load,
                        onRetry: () =>
                            ref.invalidate(bookingListAllProvider(filter)),
                      ),
                    ),
                  ),
                  data: (bookings) {
                    // The "All" tab shows only active bookings — cancelled ones
                    // live exclusively on the Cancelled tab so a cancelled
                    // booking disappears from the main list once cancelled.
                    final base = _activeChip == _StatusChip.all
                        ? bookings
                              .where((b) => b.status != BookingStatus.cancelled)
                              .toList()
                        : bookings;

                    // Shift filter is applied in-memory: a Day (or Night)
                    // filter also keeps Both bookings, because a full-day
                    // shoot covers that shift. `null` = no shift restriction.
                    final shiftFilter = filter.shift;
                    final filtered = shiftFilter == null
                        ? base
                        : base
                              .where(
                                (b) =>
                                    b.shift == shiftFilter ||
                                    b.shift == Shift.both,
                              )
                              .toList();

                    // Sorted date+time ascending (14th before 15th, Day before
                    // Night within a day) before the Day|Night split so each
                    // column below reads in chronological order.
                    final visible = filtered.toList()
                      ..sort((a, b) {
                        final byDate = _dayOnly(
                          a.date,
                        ).compareTo(_dayOnly(b.date));
                        if (byDate != 0) return byDate;
                        // Same day → Day shift before Night shift.
                        return _shiftRank(a.shift).compareTo(
                          _shiftRank(b.shift),
                        );
                      });
                    if (visible.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 120),
                          child: EmptyState(
                            icon: Icons.event_note_outlined,
                            message: loc.bookings_empty,
                          ),
                        ),
                      );
                    }
                    return _BookingListColumn(
                      bookings: visible,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        style: TextStyle(color: AppColors.film, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search bookings...',
          hintStyle: TextStyle(color: AppColors.filmMuted),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.filmMuted,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.glass,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.teal),
          ),
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.onSelected});

  final _StatusChip selected;
  final ValueChanged<_StatusChip> onSelected;

  // Booking List tabs (Heaven 2026-07-12): All · Complete · Delivery · Cancel.
  // "All" hides cancelled; Cancel keeps them reachable.
  static const _chips = [
    (_StatusChip.all, 'All'),
    (_StatusChip.complete, 'Complete'),
    (_StatusChip.delivered, 'Delivery'),
    (_StatusChip.cancelled, 'Cancel'),
  ];

  @override
  Widget build(BuildContext context) {
    // Taller strip + centred labels so "Successful"/"Delivered" are never
    // vertically clipped (the old 44px strip with vertical:8 list padding +
    // vertical:6 chip padding left too little room and cut the glyph bottoms).
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (chip, label) = _chips[index];
          final isSelected = chip == selected;
          return GestureDetector(
            onTap: () => onSelected(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // Design: active chip = solid orange fill + white text;
                // inactive = white surface with a soft hairline border.
                color: isSelected ? AppColors.orange : AppColors.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.orange
                      : AppColors.line(0.10),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppText.bodyFontFamily,
                  color: isSelected ? Colors.white : AppColors.filmDim,
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Single chronological booking list. Each row's left border + shift icon
/// is gold for Day and purple for Night, so the Day/Night distinction is
/// still obvious without breaking the date order.
class _BookingListColumn extends StatelessWidget {
  const _BookingListColumn({
    required this.bookings,
    required this.scrollController,
  });

  final List<Booking> bookings;
  final ScrollController scrollController;

  /// Sort by start time ("HH:mm") then date so each column reads time-wise.
  static int _byTime(Booking a, Booking b) {
    final byTime = a.startTime.compareTo(b.startTime);
    if (byTime != 0) return byTime;
    return a.date.compareTo(b.date);
  }

  @override
  Widget build(BuildContext context) {
    // Two columns: Day on the left, Night on the right. A Both (full-day)
    // booking covers both shifts, so it appears in each column. Within a
    // column the rows are ordered by start time.
    final dayBookings =
        bookings
            .where((b) => b.shift == Shift.day || b.shift == Shift.both)
            .toList()
          ..sort(_byTime);
    final nightBookings =
        bookings
            .where((b) => b.shift == Shift.night || b.shift == Shift.both)
            .toList()
          ..sort(_byTime);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      // On web the two-column Day|Night split is capped and centred so each
      // card stays a comfortable width on a wide desktop window instead of
      // each column ballooning to ~700px. Mobile is unchanged (pass-through).
      child: WebFormWidth(
        maxWidth: 960,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ShiftColumn(
              title: 'DAY',
              color: AppColors.gold,
              bookings: dayBookings,
              // Design: Day cards carry the accent as a left edge, Night as a
              // right edge — so the two columns visually "face" each other.
              accentSide: _AccentSide.left,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _ShiftColumn(
              title: 'NIGHT',
              color: AppColors.purple,
              bookings: nightBookings,
              accentSide: _AccentSide.right,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// One side of the Day | Night split: a labelled header with the count and a
/// vertical, time-ordered list of bookings for that shift.
class _ShiftColumn extends StatelessWidget {
  const _ShiftColumn({
    required this.title,
    required this.color,
    required this.bookings,
    required this.accentSide,
  });

  final String title;
  final Color color;
  final List<Booking> bookings;
  final _AccentSide accentSide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Design (.dc.html): a small filled dot + a mono "DAY · 5" caption —
        // no boxed pill. The dot carries the shift colour.
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$title · ${bookings.length}',
                style: TextStyle(
                  fontFamily: AppText.monoFontFamily,
                  color: AppColors.film,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        if (bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No $title bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.6),
                fontSize: 11.5,
              ),
            ),
          )
        else
          for (var i = 0; i < bookings.length; i++)
            // RepaintBoundary isolates each card's paint layer so scrolling
            // only repaints what actually moves, not the whole column — this
            // is the fix for the "scroll করলে কেঁপে ওঠে" jank. Only the first
            // screenful gets the staggered entrance; rows past that render in
            // place so a long list doesn't animate every card on first paint.
            RepaintBoundary(
              child: i < 8
                  ? FadeUpIn(
                      order: i,
                      child: _BookingColumnRow(
                        booking: bookings[i],
                        accentColor: color,
                        accentSide: accentSide,
                      ),
                    )
                  : _BookingColumnRow(
                      booking: bookings[i],
                      accentColor: color,
                      accentSide: accentSide,
                    ),
            ),
      ],
    );
  }
}

class _BookingColumnRow extends ConsumerWidget {
  const _BookingColumnRow({
    required this.booking,
    required this.accentColor,
    required this.accentSide,
  });

  final Booking booking;
  final Color accentColor;
  final _AccentSide accentSide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    // A pure Freelancer works FOR studios, not for end clients — they book
    // through the owner and get paid by the owner. So on their booking list
    // the "who" slot shows the COMPANY (studio owner) name, not the client's
    // (Heaven: "কোম্পানি নাম থাকবে ক্লায়েন্ট এর যায়গায়"). The owner name comes
    // from the freelancer earnings overview, keyed by event id; when a given
    // event isn't in that map yet we fall back to a neutral "Company event".
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final String displayName;
    if (role == UserRole.freelancer) {
      final ownerName = ref.watch(
        flEventOwnerNameProvider(booking.remoteId ?? booking.id),
      );
      displayName = (ownerName?.trim().isNotEmpty ?? false)
          ? ownerName!
          : 'Company event';
    } else {
      // Prefer the joined client record, but fall back to the name typed on
      // the booking itself (offline bookings may have no separate client row)
      // and finally the booking title, so a row always shows *who* it's for.
      final lookedUpName = booking.clientId == null
          ? null
          : ref.watch(clientByIdProvider(booking.clientId!)).value?.name;
      displayName = (lookedUpName?.trim().isNotEmpty ?? false)
          ? lookedUpName!
          : (booking.clientName?.trim().isNotEmpty ?? false)
          ? booking.clientName!
          : booking.title;
    }

    // Design (.dc.html): mono date "APR 12" on top, client name, then a
    // "Wedding · 12–5" meta line (event type + compact time range).
    final dateText = DateFormat('MMM d', lang).format(booking.date).toUpperCase();
    final metaText = '${booking.eventType.vibe.label} · '
        '${BookingFormat.clockRange(booking.startTime, booking.endTime, lang: lang, separator: '–')}';

    // Day cards accent the left edge, Night the right — the 3px coloured rule
    // from the mockup.
    final accentBorder = BorderSide(color: accentColor, width: 3);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: AppColors.line(0.06)),
          bottom: BorderSide(color: AppColors.line(0.06)),
          left: accentSide == _AccentSide.left
              ? accentBorder
              : BorderSide(color: AppColors.line(0.06)),
          right: accentSide == _AccentSide.right
              ? accentBorder
              : BorderSide(color: AppColors.line(0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.bookingDetail, arguments: booking.id),
          onLongPress: () => Navigator.of(context).pushNamed(
            RouteNames.bookingEdit,
            arguments: 'duplicate:${booking.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        color: AppColors.filmMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (booking.pending)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName.trim().isEmpty ? 'Untitled' : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter, required this.onApply});

  final BookingFilter filter;
  final ValueChanged<BookingFilter> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  Shift? _selectedShift;
  _DateRangePreset _dateRange = _DateRangePreset.any;

  @override
  void initState() {
    super.initState();
    // Reflect the already-applied filter so reopening the sheet keeps the
    // current shift selection instead of silently resetting to "Any".
    _selectedShift = widget.filter.shift;
  }

  ({DateTime? from, DateTime? to}) _computeDateRange(_DateRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _DateRangePreset.any:
        return (from: null, to: null);
      case _DateRangePreset.today:
        final tomorrow = today.add(const Duration(days: 1));
        return (from: today, to: tomorrow);
      case _DateRangePreset.week:
        final weekAgo = today.subtract(const Duration(days: 6));
        final tomorrow = today.add(const Duration(days: 1));
        return (from: weekAgo, to: tomorrow);
      case _DateRangePreset.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final nextMonthStart = DateTime(now.year, now.month + 1, 1);
        return (from: monthStart, to: nextMonthStart);
      case _DateRangePreset.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final thisMonthStart = DateTime(now.year, now.month, 1);
        return (from: lastMonthStart, to: thisMonthStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.filmMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filters',
            style: TextStyle(
              color: AppColors.film,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'SHIFT',
            children: [
              _FilterOptionChip(
                label: 'Any',
                isSelected: _selectedShift == null,
                onTap: () => setState(() => _selectedShift = null),
              ),
              _FilterOptionChip(
                label: 'Day',
                isSelected: _selectedShift == Shift.day,
                onTap: () => setState(() => _selectedShift = Shift.day),
                color: AppColors.gold,
              ),
              _FilterOptionChip(
                label: 'Night',
                isSelected: _selectedShift == Shift.night,
                onTap: () => setState(() => _selectedShift = Shift.night),
                color: AppColors.purple,
              ),
              _FilterOptionChip(
                label: 'Both',
                isSelected: _selectedShift == Shift.both,
                onTap: () => setState(() => _selectedShift = Shift.both),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FilterSection(
            title: 'DATE RANGE',
            children: [
              _FilterOptionChip(
                label: 'Any',
                isSelected: _dateRange == _DateRangePreset.any,
                onTap: () => setState(() => _dateRange = _DateRangePreset.any),
              ),
              _FilterOptionChip(
                label: 'Today',
                isSelected: _dateRange == _DateRangePreset.today,
                onTap: () =>
                    setState(() => _dateRange = _DateRangePreset.today),
              ),
              _FilterOptionChip(
                label: 'Week',
                isSelected: _dateRange == _DateRangePreset.week,
                onTap: () => setState(() => _dateRange = _DateRangePreset.week),
              ),
              _FilterOptionChip(
                label: 'Month',
                isSelected: _dateRange == _DateRangePreset.month,
                onTap: () =>
                    setState(() => _dateRange = _DateRangePreset.month),
              ),
              _FilterOptionChip(
                label: 'Last Month',
                isSelected: _dateRange == _DateRangePreset.lastMonth,
                onTap: () =>
                    setState(() => _dateRange = _DateRangePreset.lastMonth),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FilterSection(
            title: 'OWNER / COMPANY',
            children: [
              _FilterOptionChip(label: 'Any', isSelected: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final range = _computeDateRange(_dateRange);
                widget.onApply(
                  widget.filter.copyWith(
                    from: range.from,
                    to: range.to,
                    clearFrom: range.from == null,
                    clearTo: range.to == null,
                    shift: _selectedShift,
                    clearShift: _selectedShift == null,
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.filmDim,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.teal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppColors.filmDim,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

bool shouldShowPayment({
  required UserRole role,
  required bool hidePaymentFromTeam,
  required bool canViewPayments,
}) {
  if (!canViewPayments) return false;
  if (role == UserRole.manager && hidePaymentFromTeam) return false;
  return true;
}

/// Whether payment figures appear on the *shared event details* the owner
/// sends to the team and freelancers.
///
/// Default is OFF: shared details never expose money. Payment is included
/// only when the owner has explicitly turned on [showPaymentInShare] for
/// this booking — and then everyone who receives the share (team and
/// freelancers alike) sees it. The client invoice ignores this flag and
/// always shows payment.
bool shouldShowPaymentInShare({required bool showPaymentInShare}) {
  return showPaymentInShare;
}
