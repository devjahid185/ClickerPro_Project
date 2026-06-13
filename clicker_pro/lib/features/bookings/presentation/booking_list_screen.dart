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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/role/capability.dart';
import '../../../core/navigation/route_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_colors.dart';
import '../../auth/domain/user_role.dart';
import '../../public_booking/application/public_booking_providers.dart';
import '../../settings/application/language_controller.dart';
import '../application/booking_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/shift.dart';

enum _StatusChip { all, confirmed, successful, delivered, cancelled }

enum _DateRangePreset { any, today, week, month, lastMonth }

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Reached near the bottom, increment page
      final currentPage = ref.read(bookingListPageProvider);
      ref.read(bookingListPageProvider.notifier).state = currentPage + 1;
    }
  }

  _StatusChip get _activeChip {
    final statuses = ref.read(bookingFilterProvider).statuses;
    if (statuses.isEmpty) return _StatusChip.all;
    if (statuses.length == 1) {
      if (statuses.contains(BookingStatus.confirmed)) {
        return _StatusChip.confirmed;
      }
      if (statuses.contains(BookingStatus.delivered)) {
        return _StatusChip.delivered;
      }
      if (statuses.contains(BookingStatus.cancelled)) {
        return _StatusChip.cancelled;
      }
    }
    return _StatusChip.successful;
  }

  Set<BookingStatus> _statusesForChip(_StatusChip chip) {
    switch (chip) {
      case _StatusChip.all:
        return {};
      case _StatusChip.confirmed:
        // "Confirmed" now also surfaces pending bookings so nothing is
        // hidden after the dedicated Pending chip was removed.
        return {BookingStatus.pending, BookingStatus.confirmed};
      case _StatusChip.successful:
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
      await SharePlus.instance.share(
        ShareParams(
          text:
              'আমাদের স্টুডিওতে বুকিং দিতে এই লিংকে আপনার তথ্য দিন:\n${issued.url}',
          subject: 'Booking link',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('লিংক আনা যায়নি — আবার চেষ্টা করুন।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(bookingFilterProvider);
    final listAsync = ref.watch(bookingListProvider(filter));
    final policy = ref.watch(bookingsPolicyProvider);
    final loc = AppLocalizations.of(context);
    final bookings = listAsync.valueOrNull;
    final totalCount = bookings?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          loc.bookings_title,
          style: const TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: loc.bookings_calendar,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.gold,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.calendar),
          ),
          IconButton(
            tooltip: 'Waitlist',
            icon: const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.gold,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.waitlist),
          ),
          if (policy.can(Capability.approvePublicBooking)) ...[
            IconButton(
              tooltip: 'Share booking link',
              icon: const Icon(Icons.share_outlined, color: AppColors.teal),
              onPressed: () => _shareBookingLink(context),
            ),
            IconButton(
              tooltip: 'Pending requests',
              icon: const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.gold,
              ),
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(RouteNames.pendingPublicBookings),
            ),
          ],
          if (listAsync.hasValue)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 12,
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
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                  ref.read(bookingFilterProvider.notifier).state = ref
                      .read(bookingFilterProvider)
                      .copyWith(
                        search: value.isEmpty ? null : value,
                        clearSearch: value.isEmpty,
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
            if (!filter.isEmpty)
              _ActiveFilterChips(
                filter: filter,
                onDismiss: (type) {
                  final current = ref.read(bookingFilterProvider);
                  switch (type) {
                    case _FilterType.status:
                      ref.read(bookingFilterProvider.notifier).state = current
                          .copyWith(statuses: {});
                      break;
                    case _FilterType.dateRange:
                      ref.read(bookingFilterProvider.notifier).state = current
                          .copyWith(clearFrom: true, clearTo: true);
                      break;
                    case _FilterType.search:
                      ref.read(bookingFilterProvider.notifier).state = current
                          .copyWith(clearSearch: true);
                      break;
                  }
                },
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.teal,
                backgroundColor: AppColors.voidElevated,
                onRefresh: () async {
                  ref.read(bookingListPageProvider.notifier).state = 0;
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
                            ref.invalidate(bookingListProvider(filter)),
                      ),
                    ),
                  ),
                  data: (bookings) {
                    // One unified list — no চলমান/শেষ হওয়া split. Every
                    // event (including cancelled) shows here, sorted by
                    // date so the nearest events surface first. Use the
                    // status chips to narrow by status.
                    final visible = bookings.toList()
                      ..sort((a, b) => a.date.compareTo(b.date));
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
                    final dayBookings = visible
                        .where(
                          (b) => b.shift == Shift.day || b.shift == Shift.both,
                        )
                        .toList();
                    final nightBookings = visible
                        .where(
                          (b) =>
                              b.shift == Shift.night || b.shift == Shift.both,
                        )
                        .toList();
                    return _DayNightColumns(
                      dayBookings: dayBookings,
                      nightBookings: nightBookings,
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
        style: const TextStyle(color: AppColors.film, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search bookings...',
          hintStyle: const TextStyle(color: AppColors.filmMuted),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.filmMuted,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.glass,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal),
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

  static const _chips = [
    (_StatusChip.all, 'All'),
    (_StatusChip.confirmed, 'Confirmed'),
    (_StatusChip.successful, 'Successful'),
    (_StatusChip.delivered, 'Delivered'),
    (_StatusChip.cancelled, 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (chip, label) = _chips[index];
          final isSelected = chip == selected;
          return GestureDetector(
            onTap: () => onSelected(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.15)
                    : AppColors.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.teal : AppColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.teal : AppColors.filmDim,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _FilterType { status, dateRange, search }

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.onDismiss});

  final BookingFilter filter;
  final ValueChanged<_FilterType> onDismiss;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.statuses.isNotEmpty) {
      chips.add(_buildChip('Status', () => onDismiss(_FilterType.status)));
    }
    if (filter.from != null || filter.to != null) {
      chips.add(
        _buildChip('Date Range', () => onDismiss(_FilterType.dateRange)),
      );
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      chips.add(
        _buildChip('"${filter.search}"', () => onDismiss(_FilterType.search)),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: chips,
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDismiss) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(color: AppColors.teal, fontSize: 11),
        ),
        deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.teal),
        onDeleted: onDismiss,
        backgroundColor: AppColors.teal.withValues(alpha: 0.08),
        side: const BorderSide(color: AppColors.teal, width: 0.5),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DayNightColumns extends StatelessWidget {
  const _DayNightColumns({
    required this.dayBookings,
    required this.nightBookings,
    required this.scrollController,
  });

  final List<Booking> dayBookings;
  final List<Booking> nightBookings;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _ColumnHeader(
                  label: 'DAY',
                  count: dayBookings.length,
                  color: AppColors.gold,
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.glassBorder),
              Expanded(
                child: _ColumnHeader(
                  label: 'NIGHT',
                  count: nightBookings.length,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 1,
          color: AppColors.glassBorder,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 96),
                  itemCount: dayBookings.length,
                  itemBuilder: (context, index) => FadeUpIn(
                    order: index.clamp(0, 8),
                    child: _BookingColumnRow(
                      booking: dayBookings[index],
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 2,
                      ),
                      iconColor: AppColors.gold,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.glassBorder),
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 96),
                  itemCount: nightBookings.length,
                  itemBuilder: (context, index) => FadeUpIn(
                    order: index.clamp(0, 8),
                    child: _BookingColumnRow(
                      booking: nightBookings[index],
                      borderSide: const BorderSide(
                        color: AppColors.purple,
                        width: 2,
                      ),
                      iconColor: AppColors.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
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

class _BookingColumnRow extends ConsumerWidget {
  const _BookingColumnRow({
    required this.booking,
    required this.borderSide,
    required this.iconColor,
  });

  final Booking booking;
  final BorderSide borderSide;
  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    // Prefer the joined client record, but fall back to the name typed on
    // the booking itself (offline bookings may have no separate client row)
    // and finally the booking title, so a row always shows *who* it's for.
    final lookedUpName = booking.clientId == null
        ? null
        : ref.watch(clientByIdProvider(booking.clientId!)).value?.name;
    final displayName = (lookedUpName?.trim().isNotEmpty ?? false)
        ? lookedUpName!
        : (booking.clientName?.trim().isNotEmpty ?? false)
        ? booking.clientName!
        : booking.title;

    final dayText = DateFormat('d', lang).format(booking.date);
    final monthText = DateFormat(
      'MMM',
      lang,
    ).format(booking.date).toUpperCase();
    final shiftIcon = booking.shift == Shift.day
        ? Icons.wb_sunny_outlined
        : booking.shift == Shift.night
        ? Icons.nightlight_outlined
        : Icons.wb_twilight_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: borderSide),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.bookingDetail, arguments: booking.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.voidElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayText,
                        style: const TextStyle(
                          color: AppColors.film,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthText,
                        style: TextStyle(
                          color: AppColors.filmDim.withValues(alpha: 0.85),
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.trim().isEmpty ? 'Untitled' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.film,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        // Only take the width the icon + label need; without
                        // this the label's letterSpacing pushed the row ~17px
                        // past the narrow DAY/NIGHT column and overflowed.
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(shiftIcon, color: iconColor, size: 12),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              booking.shift.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (booking.pending)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                SizedBox(
                  width: 28,
                  height: 32,
                  child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.filmMuted,
                    size: 18,
                  ),
                  // Keep the trailing action compact in the narrow
                  // DAY/NIGHT columns.
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 32,
                  ),
                  color: AppColors.voidElevated,
                  onSelected: (value) {
                    if (value == 'duplicate') {
                      Navigator.of(context).pushNamed(
                        RouteNames.bookingEdit,
                        arguments: 'duplicate:${booking.id}',
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: AppColors.teal, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Duplicate',
                            style: TextStyle(color: AppColors.film, fontSize: 13),
                          ),
                        ],
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
          const Text(
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
              child: const Text(
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
          style: const TextStyle(
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
