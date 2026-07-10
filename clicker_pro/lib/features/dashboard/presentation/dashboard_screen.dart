// lib/features/dashboard/presentation/dashboard_screen.dart
//
// Clicker Pro — Dashboard (Dark Luxury Lens)
//
// Visual: v12 architecture — Unified Layout, Role-aware Data
//   • Topbar with menu / Clicker Pro brand + studio subtitle / search / avatar
//   • Weekday strip (7 days Mon→Sun, today highlighted teal)
//   • Split hero (big today count teal glow + Upcoming/Total mini cards)
//   • Delivered strip (count + mini bar chart)
//   • Quick action row (4 buttons, role-adaptive)
//   • Announcement card (orange/gold gradient + read pips)
//   • Finance row (role-adaptive: Owner/Both/Manager/Freelancer)
//   • Info row (Holidays · Cancelled)
//   • Weather card (indigo)
//   • Drawer with MAIN / FINANCE / OPERATIONS / ACCOUNT groups
//   • Bottom nav: Home · Booking · FAB · Finance · Settings
//
// Wiring (this slice):
//   • currentUserProvider          — name, role label, avatar initials, studio subtitle
//   • languageControllerProvider   — i18n labels (legacy AppStrings.get shim)
//   • rolePolicyProvider           — capability gating
//   • dashboardMetricsProvider     — typed metric tile data
//   • dashboardSelectedDayProvider — weekday-strip selection
//   • userRepositoryProvider       — refreshFromRemote on pull-to-refresh
//   • sessionControllerProvider    — logout (drawer)
//   • connectivityProvider         — OfflineBanner + offline→online refresh
//
// Animation tokens used:
//   • Body fade-in              : 600ms easeOut on mount
//   • Weekday-strip cell swap   : AnimatedContainer 220ms easeOut
//   • Metric value cross-fade   : AnimatedSwitcher 180ms (refresh-friendly)
//   • Page transitions          : AppRouter.lensPageRoute (slide+fade,
//                                 280ms in / 200ms out, Cubic(0.2,0.8,0.2,1))

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/notifications/event_reminder_service.dart';
import '../../../core/update/app_update_service.dart';
import '../../../core/providers.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/sync_indicator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/user_role.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/booking_status/booking_status.dart';
import '../../../core/format/booking_format.dart';
import '../../../core/format/currency.dart';
import '../../home_widget/data/widget_refresher.dart';
import '../../home_widget/domain/widget_data.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking_filter.dart';
import '../../broadcasts/presentation/broadcast_popup.dart';
import '../../push/application/fcm_bootstrap.dart';
import '../../announcements/application/announcement_providers.dart';
import '../../announcements/domain/announcement.dart';
import '../../profile/application/profile_controllers.dart';
import '../../search/presentation/global_search_sheet.dart';
import '../../profile/domain/user_model.dart';
import '../../settings/application/language_controller.dart';
import '../application/dashboard_preferences.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_section.dart';
import 'web_dashboard.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Track connectivity transitions so we can trigger a background refresh
  // when the network returns (Requirement 6.7).
  bool? _wasOnline;

  // ─── Stagger entry (Task 20.4 / MOD-04) ─────────────────────────
  // Each major body section fades + slides up 12px → 0px over 320ms with an
  // 80ms delay between sections, producing the cascade entry.
  static const int _staggerSlots = 8;
  final List<bool> _visible = List<bool>.filled(_staggerSlots, false);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    for (var i = 0; i < _staggerSlots; i++) {
      Future<void>.delayed(Duration(milliseconds: 80 * i), () {
        if (!mounted) return;
        setState(() => _visible[i] = true);
      });
    }

    // Admin broadcast popup — shows once per broadcast on app open,
    // auto-dismisses after 10s (see broadcast_popup.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBroadcastPopupIfNeeded(context, ref);
      // Register this device for push notifications (fail-soft).
      initPushNotifications(ref);
      // Prime the on-device event-reminder channel + permissions so the
      // "1 hour before" alarms can be scheduled (fail-soft), then re-arm a
      // reminder for every upcoming booking. scheduleForBooking only runs on
      // in-app save, so server-synced / other-device / pre-feature bookings
      // never had an alarm — this is the fix for "event আগে notification
      // আসে না". Fully fail-soft; never blocks the dashboard.
      _syncEventReminders();
      // Over-the-air update check — prompts if a newer APK is published.
      AppUpdateService.checkAndPrompt(context, ref.read(apiClientProvider));
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Re-arms the on-device "1 hour before" reminder for every upcoming,
  /// non-terminal booking on app open. scheduleForBooking only runs on
  /// in-app save, so bookings that synced from the server, were created on
  /// another device, or predate the reminder feature never had an alarm —
  /// this is the fix for "event আগে notification আসে না". Fail-soft: any
  /// error is swallowed so it can never block the dashboard from loading.
  Future<void> _syncEventReminders() async {
    await EventReminderService.instance.init();
    try {
      final bookings =
          await ref.read(bookingListAllProvider(const BookingFilter()).future);
      final today = DateTime.now();
      final midnight = DateTime(today.year, today.month, today.day);
      final upcoming = bookings
          .where((b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.completed &&
              !b.date.isBefore(midnight))
          .map((b) => ReminderBooking(
                id: b.id,
                title: b.clientName?.trim().isNotEmpty == true
                    ? b.clientName!.trim()
                    : b.title,
                eventDate: b.date,
                startTime: b.startTime,
                endTime: b.endTime,
                venue: b.venue,
                clientName: b.clientName,
                clientPhone: b.clientPhone,
              ));
      await EventReminderService.instance.syncUpcomingReminders(upcoming);
    } catch (e) {
      // Non-fatal — reminders are best-effort, the dashboard must still load.
      AppLogger.w('dashboard', 'reminder sync failed: $e');
    }
  }

  String _lang() => ref
      .read(languageControllerProvider)
      .maybeWhen(data: (c) => c, orElse: () => 'en');

  String t(String key) => AppStrings.get(key, _lang());

  // ─── Navigation helpers ─────────────────────────────────────────────
  void _pushNamed(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        // Home — already here.
        break;
      case 1:
        _pushNamed(RouteNames.bookings);
        break;
      case 2:
        // Center FAB handled in `_navFab`.
        break;
      case 3:
        // Finance adapts per role: freelancers get the earnings face,
        // owners the studio face (FinanceScreen decides internally).
        _pushNamed(RouteNames.finance);
        break;
      case 4:
        _pushNamed(RouteNames.settings);
        break;
    }
  }

  Future<void> _onRefresh() async {
    try {
      await ref.read(userRepositoryProvider).refreshFromRemote();
    } catch (_) {
      // Silent: cached data + OfflineBanner already convey the state.
    }
    ref.invalidate(dashboardMetricsProvider);
    // Hold the spinner briefly so the gesture feels responsive.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// Builds the home-widget snapshot from the fresh metrics + the current
  /// month's calendar and hands it to [WidgetRefresher] (deduplicated,
  /// fail-soft, Android-only effect).
  void _pushHomeWidgetSnapshot(DashboardMetrics m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month =
        ref
            .read(calendarBookingsProvider((year: now.year, month: now.month)))
            .valueOrNull ??
        const [];
    final upcoming =
        month
            .where(
              (b) =>
                  b.status != BookingStatus.cancelled &&
                  !DateTime(
                    b.date.year,
                    b.date.month,
                    b.date.day,
                  ).isBefore(today),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
          });
    final next = upcoming.firstOrNull;

    WidgetRefresher.push(
      WidgetData(
        todayEventsCount: m.todayEvents,
        dueAmount: m.pendingDue / 100, // minor units → taka
        nextEventTitle: next == null
            ? null
            : (next.clientName?.trim().isNotEmpty == true
                  ? next.clientName!.trim()
                  : next.title),
        nextEventTime: next == null
            ? null
            : '${BookingFormat.dateOnly(next.date, lang: 'en')} · '
                  '${BookingFormat.clockTime(next.startTime)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch connectivity so we can refresh on offline → online transitions.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      next.whenData((online) {
        if (_wasOnline == false && online == true) {
          // Just came back online: refresh user + metrics in the background.
          ref.read(userRepositoryProvider).refreshFromRemote();
          ref.invalidate(dashboardMetricsProvider);
        }
        _wasOnline = online;
      });
    });

    // Feed the Android home widget whenever the metrics recompute. Fail-soft
    // and deduplicated inside WidgetRefresher; a no-op off Android.
    ref.listen<AsyncValue<DashboardMetrics>>(dashboardMetricsProvider, (
      prev,
      next,
    ) {
      final m = next.valueOrNull;
      if (m == null) return;
      _pushHomeWidgetSnapshot(m);
    });

    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    // On wide web the WebNavShell supplies the permanent sidebar + chrome, so
    // the dashboard's own drawer and bottom nav would be redundant — hide them.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      extendBody: true,
      // On web the WebShell paints a rich ambient backdrop behind the app; a
      // transparent scaffold lets that colour show through so the glass cards
      // actually read as glass. On mobile this is a no-op (WebShell is a
      // pass-through there) and the theme background still applies.
      backgroundColor: kIsWeb ? Colors.transparent : null,
      appBar: webWide ? null : _buildAppBar(user),
      drawer: webWide ? null : _buildSidebar(user),
      body: Column(
        children: [
          // Network indicator — invisible when online (zero-height).
          const OfflineBanner(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              // On wide web the WebNavShell owns the chrome; render the
              // dedicated desktop dashboard (Studio Sage) instead of the
              // mobile body. Mobile + narrow web keep the original layout
              // 100% unchanged.
              child: webWide
                  ? WebDashboard(user: user)
                  : RefreshIndicator(
                      color: AppColors.orange,
                      backgroundColor: AppColors.voidElevated,
                      strokeWidth: 2.8,
                      onRefresh: _onRefresh,
                      child: _buildBody(user),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: webWide ? null : _buildBottomNav(),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(UserModel? user) {
    final initials = user?.avatarInitials ?? '..';
    final subtitle = user?.studioLabel ?? 'Company';

    return AppBar(
      elevation: 0,
      leading: Builder(
        builder: (BuildContext ctx) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(Icons.menu, color: AppColors.film, size: 20),
            ),
          ),
        ),
      ),
      titleSpacing: 4,
      title: _AnimatedBrand(subtitle: subtitle),
      centerTitle: false,
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showSearchSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(Icons.search, color: AppColors.film, size: 20),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pushNamed(RouteNames.notifications),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.film,
                size: 20,
              ),
            ),
          ),
        ),
        const SyncIndicator(),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _avatarButton(initials, user?.id, user?.avatarUrl),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.line(0.04)),
      ),
    );
  }

  Widget _avatarButton(String initials, String? userId, String? avatarUrl) {
    final image = _avatarImage(avatarUrl);
    final avatar = Material(
      child: InkWell(
        onTap: () => _pushNamed(RouteNames.profile),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Accent fill is only the backdrop for the initials; with a photo
            // it would show as an orange ring behind the image.
            color: image == null ? AppColors.accent : null,
            border: Border.all(color: AppColors.line(0.12), width: 2),
            // Show the user's profile photo when set; fall back to initials.
            image: image == null
                ? null
                : DecorationImage(image: image, fit: BoxFit.cover),
          ),
          alignment: Alignment.center,
          child: image != null
              ? null
              : Text(
                  initials,
                  style: TextStyle(
                    fontFamily: AppText.brand.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onAccent,
                  ),
                ),
        ),
      ),
    );
    if (userId == null) return avatar;
    return Hero(tag: 'user-avatar-$userId', child: avatar);
  }

  /// Resolves a profile-photo provider from a stored avatar string, which may
  /// be a remote URL or a base64 data-URI (the web app stores logos/photos as
  /// data-URIs). Returns null when there's nothing valid to show.
  ImageProvider? _avatarImage(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:image')) {
      final comma = raw.indexOf(',');
      if (comma == -1) return null;
      try {
        return MemoryImage(base64Decode(raw.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }
    return null;
  }

  // ─── Search bottom sheet (placeholder until search is shipped) ────────
  void _showSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      builder: (_) => const GlobalSearchSheet(),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────────
  Widget _buildBody(UserModel? user) {
    final sections = ref.watch(dashboardPrefsProvider);
    final enabled = sections.where((s) => s.enabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return ListView(
      // Bottom padding clears the floating 56px nav bar + its margin so
      // the last card (weather) is never hidden behind it.
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Platform broadcasts now arrive as the 10s popup + the drawer's
        // "Platform Updates" screen — the persistent welcome banner was
        // removed per design feedback.
        for (var i = 0; i < enabled.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _stagger(i, _buildSection(enabled[i].type, user)),
        ],
      ],
    );
  }

  Widget _buildSection(DashboardSectionType type, UserModel? user) {
    switch (type) {
      case DashboardSectionType.weekStrip:
        return _buildWeekStrip();
      case DashboardSectionType.splitHero:
        return _buildSplitHero(user);
      case DashboardSectionType.deliveredBar:
        return _buildDeliveredStrip();
      case DashboardSectionType.quickActions:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(t('quick_actions')),
            const SizedBox(height: 10),
            _buildQuickActions(user),
          ],
        );
      case DashboardSectionType.announcement:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Announcement', showMore: true),
            const SizedBox(height: 10),
            _buildAnnouncementCard(),
          ],
        );
      case DashboardSectionType.financeRow:
        return _buildPaymentRow(user);
      case DashboardSectionType.holidays:
        return _buildInfoRow();
      case DashboardSectionType.weather:
        return _buildWeatherCard();
    }
  }

  /// Wraps a dashboard body section with the MOD-04 stagger entry: fade
  /// 0→1 + slide-up 12px → 0 over 320ms, gated by [_visible] which flips
  /// per index in [initState] with an 80ms cascade.
  Widget _stagger(int index, Widget child) {
    final on = _visible[index];
    return AnimatedSlide(
      offset: on ? Offset.zero : const Offset(0, 0.04),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: on ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  // ─── Weekday strip (Mon → Sun of the current week) ─────────────────
  Widget _buildWeekStrip() {
    final selected = ref.watch(dashboardSelectedDayProvider);
    final weekEventCounts = ref.watch(weekEventCountsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List<DateTime>.generate(
      7,
      (i) => monday.add(Duration(days: i)),
    );

    const dowLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line(0.14)),
      ),
      child: Row(
        children: List.generate(days.length, (int i) {
          final d = days[i];
          final isToday = _isSameDay(d, today);
          final isSelected = _isSameDay(d, selected);
          final hasEvent = weekEventCounts[i] > 0;

          // Today: filled teal always. Selected (non-today): light tint.
          final Decoration? cellDecoration = isToday
              ? BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.40),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : isSelected
              ? BoxDecoration(
                  color: AppColors.line(0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.line(0.10)),
                )
              : null;

          final Color labelColor = isToday
              ? AppColors.onAccent
              : AppColors.filmDim.withValues(alpha: 0.65);
          final Color numColor = isToday ? AppColors.onAccent : AppColors.film;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(dashboardSelectedDayProvider.notifier).state = d,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: cellDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dowLabels[i],
                      style: TextStyle(
                        fontFamily: AppText.sectionTitle.fontFamily,
                        fontSize: 8.5,
                        letterSpacing: 0.85,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontFamily: AppText.body.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: numColor,
                        height: 1.0,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 3,
                      child: hasEvent || isToday
                          ? Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? AppColors.onAccent
                                    : AppColors.teal,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Split hero (today count + Upcoming/Total) ─────────────────────
  Widget _buildSplitHero(UserModel? user) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    return metricsAsync.when(
      loading: () => Row(
        children: [
          Expanded(child: _splitHeroLoadingCard()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _splitHeroLoadingCard(),
                const SizedBox(height: 10),
                _splitHeroLoadingCard(),
              ],
            ),
          ),
        ],
      ),
      error: (_, stack) => Row(
        children: [
          Expanded(child: _splitHeroErrorCard()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _splitHeroErrorCard(),
                const SizedBox(height: 10),
                _splitHeroErrorCard(),
              ],
            ),
          ),
        ],
      ),
      data: (m) {
        final dayNight = (m.todayDayEvents, m.todayNightEvents);
        // IntrinsicHeight so the tall orange hero and the stacked Upcoming/Total
        // column share one height — matching the design's side-by-side balance.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: Big today count card ──
              // Design: solid orange (#E2620E) hero, radius 22, decorative white
              // corner circle, mono "TODAY" label, 58px white figure (no pad),
              // "events scheduled" subtitle, Day/Night pills on white-16 tint.
              Expanded(
                flex: 122, // design split ratio 1.22 : 1
                child: GestureDetector(
                  onTap: _openTodayEvents,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        // HTML: 120px circle, offset -30/-30, white @ 6%.
                        _cornerGlow(size: 120, right: -30, top: -30),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY',
                              style: TextStyle(
                                fontFamily: AppText.monoFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onAccent.withValues(
                                  alpha: 0.72,
                                ),
                                letterSpacing: 0.16 * 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                '${m.todayEvents}',
                                key: ValueKey('hero-today-${m.todayEvents}'),
                                style: TextStyle(
                                  fontFamily: AppText.brandFontFamily,
                                  fontSize: 58,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onAccent,
                                  height: 0.92,
                                  letterSpacing: -0.04 * 58,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'events scheduled',
                              style: TextStyle(
                                fontFamily: AppText.bodyFontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onAccent.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _dayNightPill(
                                  label: 'Day',
                                  count: dayNight.$1,
                                  dotColor: const Color(0xFFF2C75B),
                                ),
                                const SizedBox(width: 7),
                                _dayNightPill(
                                  label: 'Night',
                                  count: dayNight.$2,
                                  dotColor: const Color(0xFFB7A6F0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Right: Upcoming + Total stacked (each fills half the hero) ──
              Expanded(
                flex: 100,
                child: Column(
                  children: [
                    Expanded(
                      child: _miniHeroCard(
                        title: 'Upcoming',
                        value: '${m.upcomingEvents}',
                        color: AppColors.infoTeal,
                        subtitle: 'not yet shot',
                        labelColor: Colors.black,
                        subtitleColor: Colors.black,
                        onTap: _openUpcomingEvents,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _miniHeroCard(
                        title: 'Total',
                        value: '${m.totalEvents}',
                        color: AppColors.infoBlue,
                        subtitle: 'this year',
                        labelColor: const Color(0xFFDD8D0A),
                        subtitleColor: Colors.white,
                        onTap: _openAllEvents,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Decorative corner circle for the filled stat cards — matches the .dc.html
  // mockup EXACTLY: a plain solid translucent circle (NOT a radial glow),
  // 120px offset -30/-30 into the top-right corner, white @ 6% opacity
  // (rgba(255,255,255,0.06) in the HTML). The card's `clipBehavior: antiAlias`
  // crops it to the rounded corner, reproducing the HTML's `overflow:hidden`.
  Widget _cornerGlow({
    double size = 120,
    double? top = -30,
    double? right = -30,
    double? left,
    double? bottom,
    double opacity = 0.06,
  }) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }

  // Design: pill on white-16 tint over the orange hero, white label text and a
  // small colored dot (Day = amber, Night = violet).
  Widget _dayNightPill({
    required String label,
    required int count,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontFamily: AppText.bodyFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniHeroCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
    Color labelColor = Colors.white,
    Color subtitleColor = Colors.white,
  }) {
    // ClickerPro (light): FILLED data cards (#00898B / #3541AF) with a white
    // figure. Noir (dark): per the dark spec §4.1 these are plain dark StatCards
    // — dark `card` surface + hairline, the figure carries the accent colour and
    // the label/subtitle drop to the muted tones.
    final bool noir = AppColors.isDark;
    final Color cardBg = noir ? AppColors.glass : color;
    final Color figureColor = noir ? color : AppColors.onAccent;
    final Color labelC = noir ? AppColors.filmMuted : labelColor;
    final Color subtitleC = noir ? AppColors.filmDim : subtitleColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        clipBehavior: Clip.antiAlias,
        decoration: noir
            ? AppColors.glassCardDecoration(radius: 18)
            : BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
        child: Stack(
          children: [
            // HTML: 120px circle, white @ 6%, pushed into the top-right corner.
            if (!noir) _cornerGlow(size: 120, top: -55, right: -50),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelC,
                    letterSpacing: 0.12 * 12,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    value,
                    key: ValueKey('mini-hero-$title-$value'),
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: figureColor,
                      height: 1.0,
                      letterSpacing: -0.03 * 30,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppText.bodyFontFamily,
                      fontSize: 13,
                      color: subtitleC,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _splitHeroLoadingCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.10)),
      ),
      child: const LensLoader(size: 22),
    );
  }

  Widget _splitHeroErrorCard() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.10)),
      ),
      child: ErrorState(
        message: 'Failed to load',
        onRetry: () => ref.invalidate(dashboardMetricsProvider),
      ),
    );
  }

  // "+12 this month" caption for the Delivered strip. Reads the live
  // this-month delivered count; hides the "+N" when nothing shipped yet.
  String _deliveredThisMonthLabel() {
    final n = ref.watch(deliveredThisMonthProvider);
    return n > 0 ? '+$n this month' : 'this month';
  }

  // ─── Delivered strip (number + mini bar chart) ──────────────────────
  Widget _buildDeliveredStrip() {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    return metricsAsync.when(
      loading: () => Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line(0.10)),
        ),
        child: const LensLoader(size: 22),
      ),
      error: (_, stack) => const SizedBox.shrink(),
      data: (m) {
        final bool noir = AppColors.isDark;
        return GestureDetector(
          onTap: _openDeliveredEvents,
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            // Light: solid sage-green (#397564) filled strip.
            // Noir: plain dark `card` strip (spec §4.1) — number in text, "+N" green.
            decoration: noir
                ? AppColors.glassCardDecoration(radius: 18)
                : BoxDecoration(
                    color: AppColors.sageData,
                    borderRadius: BorderRadius.circular(18),
                  ),
            child: Stack(
              children: [
                if (!noir) _cornerGlow(size: 120, right: -50, top: -55),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontFamily: AppText.monoFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: noir
                                ? AppColors.filmMuted
                                : AppColors.onAccent,
                            letterSpacing: 0.12 * 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${m.successEvents}',
                              style: TextStyle(
                                fontFamily: AppText.brandFontFamily,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: noir
                                    ? AppColors.film
                                    : AppColors.onAccent,
                                height: 1.0,
                                letterSpacing: -0.03 * 28,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _deliveredThisMonthLabel(),
                              style: TextStyle(
                                fontFamily: AppText.bodyFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: noir ? AppColors.green : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Mini bar chart — last 4 weeks of delivered/completed events.
                    _miniBarChart(ref.watch(deliveredTrendProvider)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniBarChart(List<int> trend) {
    // Mini bar chart on the sage Delivered strip — one bar per week (oldest →
    // newest). Heights scale to the busiest week; the newest bar is emphasised
    // in brand orange, earlier ones in warm peach tints (design tokens).
    const minH = 6.0;
    const maxH = 40.0;
    final peak = trend.fold<int>(0, (m, v) => v > m ? v : m);
    final last = trend.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(trend.length, (i) {
        final h = peak == 0 ? minH : minH + (maxH - minH) * (trend[i] / peak);
        // Newest = accent; earlier bars step down. Light uses warm peach tints;
        // Noir uses the dark-green ramp from the dark spec (#5F7A2A / #2B3320).
        final bool noir = AppColors.isDark;
        final color = i == last
            ? AppColors.orange
            : i >= last - 1
            ? (noir ? const Color(0xFF5F7A2A) : const Color(0xFFEFB68E))
            : (noir ? const Color(0xFF2B3320) : const Color(0xFFF6D9C4));
        return Container(
          width: 7,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, {bool showMore = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppText.body.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.film,
            letterSpacing: -0.2,
          ),
        ),
        if (showMore)
          Text(
            'View All  ›',
            style: TextStyle(
              fontFamily: AppText.body.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              letterSpacing: 0.2,
            ),
          ),
      ],
    );
  }

  // ─── Quick action row (role-adaptive) ─────────────────────────────
  // Calendar · Calculator · Notes · Team Chat, plus
  // Expense (Freelancer/Both) or Team (Owner/Both/Manager) depending on
  // role. More entries than comfortably fit one screen width, so the row
  // scrolls horizontally instead of being squeezed into equal Expanded
  // slots — every action stays a fixed, tappable size regardless of count.
  Widget _buildQuickActions(UserModel? user) {
    final policy = RolePolicy(user?.role ?? UserRole.owner);

    final actions = <Widget>[
      _qaBtn(
        icon: Icons.calendar_month_rounded,
        color: AppColors.accent,
        label: t('btn_calendar'),
        routeName: RouteNames.calendar,
      ),
      _qaBtn(
        icon: Icons.chat_bubble_rounded,
        color: AppColors.teal,
        label: 'Team Chat',
        routeName: RouteNames.chat,
      ),
      if (policy.can(Capability.accessTeam))
        _qaBtn(
          icon: Icons.groups_rounded,
          color: AppColors.purple,
          label: 'Team',
          routeName: RouteNames.team,
        ),
      if (policy.can(Capability.viewFinancials))
        _qaBtn(
          icon: Icons.receipt_long_rounded,
          color: AppColors.orange,
          label: 'Expense',
          routeName: RouteNames.financeExpenses,
        ),
      _qaBtn(
        icon: Icons.calculate_rounded,
        color: AppColors.indigo,
        label: 'Calculator',
        routeName: RouteNames.calculator,
      ),
      _qaBtn(
        icon: Icons.sticky_note_2_rounded,
        color: AppColors.green,
        label: 'Notes',
        routeName: RouteNames.notes,
      ),
    ];

    return SizedBox(
      // 86 clipped the label under real device fonts (icon 38 + gap 7 +
      // one text line + 24 vertical padding routinely exceeds 86px) —
      // that's the "OVERFLOWEDBOTTOM" debug banner replacing every label.
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => actions[i],
      ),
    );
  }

  Widget _qaBtn({
    required IconData icon,
    required Color color,
    required String label,
    required String routeName,
  }) {
    return TapScale(
      onTap: () => _pushNamed(routeName),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line(0.14)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppText.body.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.filmDim,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Announcement — live data from announcementListControllerProvider ──
  Widget _buildAnnouncementCard() {
    final announcementsAsync = ref.watch(sortedAnnouncementsProvider);

    // The section header is always rendered above this card, so an
    // invisible card here looked like a broken/missing announcement box.
    // Loading / error / empty all render a real placeholder box that
    // links to the Announcements screen instead of disappearing.
    Widget placeholderBox(String message) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(RouteNames.announcements),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line(0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.filmDim.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return announcementsAsync.when(
      loading: () => placeholderBox('Loading announcements…'),
      error: (_, _) =>
          placeholderBox('Could not load announcements — tap to retry.'),
      data: (items) {
        final active = items.where((a) => !a.isExpired).toList();
        if (active.isEmpty) {
          return placeholderBox('No announcements yet — tap to post one.');
        }
        final a = active.first;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.announcements);
          },
          child: _AnnouncementCardView(announcement: a),
        );
      },
    );
  }

  // ─── Finance row — role adaptive ───────────────────────────────────
  // Owner / Both: Collection (teal) + Due (coral)
  // Freelancer: Received (teal) + Pending Payout (coral) — different labels
  // Manager: Due only (income/profit not visible)
  Widget _buildPaymentRow(UserModel? user) {
    final role = user?.role ?? UserRole.owner;
    final isFreelancer = role == UserRole.freelancer;
    final isManager = role == UserRole.manager;

    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final m = metricsAsync.value ?? DashboardMetrics.placeholder;
    final dueEntries = ref.watch(dueBreakdownProvider).valueOrNull;
    final dueSub = dueEntries == null
        ? 'tap to see events'
        : '${dueEntries.length} events with due';

    if (isManager) {
      return _buildPayCard(
        isCollect: false,
        label: 'Due',
        amount: _formatBdt(m.pendingDue),
        sub: dueSub,
        onTap: _showDueSheet,
      );
    }

    if (isFreelancer) {
      return Row(
        children: [
          Expanded(
            child: _buildPayCard(
              isCollect: true,
              label: 'Received',
              amount: _formatBdt(m.todayCollection),
              sub: 'tap for sources',
              onTap: _showCollectionSheet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildPayCard(
              isCollect: false,
              label: 'Pending\nPayout',
              amount: _formatBdt(m.pendingDue),
              sub: dueSub,
              onTap: _showDueSheet,
            ),
          ),
        ],
      );
    }

    // Owner / Both
    return Row(
      children: [
        Expanded(
          child: _buildPayCard(
            isCollect: true,
            label: 'Today\nCollection',
            amount: _formatBdt(m.todayCollection),
            sub: 'tap for sources',
            onTap: _showCollectionSheet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPayCard(
            isCollect: false,
            label: 'Pending\nDue',
            amount: _formatBdt(m.pendingDue),
            sub: dueSub,
            onTap: _showDueSheet,
          ),
        ),
      ],
    );
  }

  /// Collection drill-down: today's collected money grouped by source
  /// (cash / bKash / bank / …) — "কোন খাত থেকে কালেকশন হয়েছে".
  void _showCollectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (ctx, sheetRef, _) {
          final async = sheetRef.watch(todayCollectionByMethodProvider);
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.line(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    "Today's collection by source",
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: LensLoader()),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Could not load the breakdown.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.filmDim),
                      ),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No payments collected today yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.filmDim),
                          ),
                        );
                      }
                      final total = entries.fold<double>(
                        0,
                        (s, e) => s + e.amount,
                      );
                      return Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in entries)
                              _CollectionSourceRow(
                                method: e.method,
                                amount: e.amount,
                              ),
                            const Divider(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                        color: AppColors.film,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ActiveCurrency.value.wrap(total.toStringAsFixed(0), spaced: true),
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Due drill-down: lists every event that still has money owed.
  /// Tapping an entry opens that event's details.
  void _showDueSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (ctx, sheetRef, _) {
          final entriesAsync = sheetRef.watch(dueBreakdownProvider);
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.line(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Events with outstanding due',
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: entriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: LensLoader()),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Could not load the due list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.filmDim.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      data: (entries) {
                        if (entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No dues 🎉',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.filmDim.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: AppColors.line(0.05)),
                          itemBuilder: (_, i) {
                            final e = entries[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.event_note_rounded,
                                  color: AppColors.coral,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                e.clientName?.trim().isNotEmpty == true
                                    ? e.clientName!
                                    : e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.film,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${e.date.day}/${e.date.month}/${e.date.year}'
                                ' · Paid ৳${e.paid.toStringAsFixed(0)}'
                                ' / ৳${e.total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.filmDim.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: Text(
                                ActiveCurrency.value.wrap(e.due.toStringAsFixed(0)),
                                style: TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).pushNamed(
                                  RouteNames.bookingDetail,
                                  arguments: e.bookingId,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatBdt(int minor) {
    // Compact active-currency formatter for tile display. minor units = paisa.
    final taka = (minor / 100).round();
    final s = taka.toString();
    // Bangladesh-style grouping (last 3, then 2-2-…). Simple version:
    final buf = StringBuffer();
    final reversed = s.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
      buf.write(reversed[i]);
    }
    return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
  }

  Widget _buildPayCard({
    required bool isCollect,
    required String label,
    required String amount,
    required String sub,
    VoidCallback? onTap,
  }) {
    final color = isCollect ? AppColors.teal : AppColors.coral;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    isCollect ? Icons.attach_money : Icons.access_time,
                    color: color,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppText.sectionTitle.fontFamily,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: AppColors.filmDim,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                amount,
                key: ValueKey(amount),
                style: TextStyle(
                  fontFamily: AppText.brand.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontFamily: AppText.sectionTitle.fontFamily,
                fontSize: 10.5,
                color: AppColors.filmDim.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info row ──────────────────────────────────────────────────────
  Widget _buildInfoRow() {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final m = metricsAsync.value ?? DashboardMetrics.placeholder;
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            emoji: '🎉',
            number: '${m.holidaysThisMonth}',
            label: 'Holidays\nThis Month',
            isCancel: false,
            // Tapping lists WHICH dates are holidays this month.
            onTap: _showHolidaySheet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoCard(
            emoji: '❌',
            number: '${m.cancelledEvents}',
            label: 'Cancelled\nEvents',
            isCancel: true,
            // Tapping opens the booking list pre-filtered to Cancelled.
            onTap: _openCancelledEvents,
          ),
        ),
      ],
    );
  }

  /// Lists this month's public holidays (date + name) in a sheet.
  void _showHolidaySheet() {
    final now = DateTime.now();
    final holidays = bdHolidaysOfMonth(now);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.line(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '🎉 ${DateFormat.MMMM().format(now)} — holidays this month',
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (holidays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No public holidays this month.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                )
              else
                for (final h in holidays)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${h.date.day}',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: TextStyle(
                                  color: AppColors.film,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                DateFormat.EEEE().format(h.date),
                                style: TextStyle(
                                  color: AppColors.filmDim.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              if (holidays.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '* May shift ±1 day depending on the moon sighting.',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.6),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the booking list showing ONLY today's events (date range =
  /// today → tomorrow), so the Today card never surfaces future dates.
  void _openTodayEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(
          from: today,
          to: today.add(const Duration(days: 1)),
          statuses: {},
        );
    _pushNamed(RouteNames.bookings);
  }

  /// Upcoming = every future event still to be done, however far ahead
  /// ("১ দিন হোক বা ১০ বছর"). No upper date bound; only incomplete statuses
  /// (delivered/completed/cancelled are excluded) so finished shoots drop off.
  void _openUpcomingEvents() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(
          from: tomorrow,
          clearTo: true,
          statuses: {
            BookingStatus.pending,
            BookingStatus.confirmed,
            BookingStatus.inProgress,
            BookingStatus.shotComplete,
          },
        );
    _pushNamed(RouteNames.bookings);
  }

  /// Total = every booking, no date/status filter.
  void _openAllEvents() {
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(clearFrom: true, clearTo: true, statuses: {});
    _pushNamed(RouteNames.bookings);
  }

  /// Opens the booking list showing every event whose shoot happened —
  /// the Complete card (shotComplete + delivered + completed, any date).
  /// Clears any date range a previous card tap (Today/Upcoming) may have
  /// left behind, otherwise it would be silently scoped to that range.
  void _openDeliveredEvents() {
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(
          statuses: {
            BookingStatus.shotComplete,
            BookingStatus.delivered,
            BookingStatus.completed,
          },
          clearFrom: true,
          clearTo: true,
        );
    _pushNamed(RouteNames.bookings);
  }

  /// Opens the booking list showing ONLY cancelled events (any date).
  /// Also clears any leftover date range so it isn't scoped to Today/Upcoming.
  void _openCancelledEvents() {
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(
          statuses: {BookingStatus.cancelled},
          clearFrom: true,
          clearTo: true,
        );
    _pushNamed(RouteNames.bookings);
  }

  Widget _buildInfoCard({
    required String emoji,
    required String number,
    required String label,
    required bool isCancel,
    VoidCallback? onTap,
  }) {
    // Design: Holiday card = white surface with emoji; Cancelled card = solid
    // orange (#E2620E) fill with a mono "CANCELLED" caption and a dark figure.
    if (isCancel) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CANCELLED',
                style: TextStyle(
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccent,
                  letterSpacing: 0.1 * 10,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  number,
                  key: ValueKey('info-$label-$number'),
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A18),
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'this month',
                style: TextStyle(
                  fontFamily: AppText.bodyFontFamily,
                  fontSize: 10.5,
                  color: AppColors.onAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line(0.06)),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    number,
                    key: ValueKey('info-$label-$number'),
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.film,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppText.bodyFontFamily,
                    fontSize: 10.5,
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weather card (strip + shoot advisory) ─────────────────────────
  Widget _buildWeatherCard() {
    final now = DateTime.now();
    final hour = now.hour;
    // Simple time-based weather hint
    final (emoji, condition, temp) = hour < 6
        ? ('🌙', 'CLEAR NIGHT', '24')
        : hour < 10
        ? ('🌤', 'MORNING SUN', '26')
        : hour < 15
        ? ('☀️', 'MOSTLY SUNNY', '32')
        : hour < 18
        ? ('⛅', 'PARTLY CLOUDY', '30')
        : ('🌇', 'EVENING', '28');

    // Is there an outdoor shoot today? Tailors the advisory.
    final monthAsync = ref.watch(
      calendarBookingsProvider((year: now.year, month: now.month)),
    );
    final hasOutdoorToday = (monthAsync.valueOrNull ?? const []).any(
      (b) =>
          b.outdoor &&
          b.date.year == now.year &&
          b.date.month == now.month &&
          b.date.day == now.day &&
          b.status != BookingStatus.cancelled,
    );
    final advisory = _weatherAdvisory(condition, hasOutdoorToday);

    // Compact one-line strip — the old oversized emoji + 30px temperature
    // crowded the column and collided with neighbouring sections.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: AppText.brand.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.film,
                  ),
                  children: [
                    TextSpan(text: temp),
                    const TextSpan(text: '°', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  condition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppText.sectionTitle.fontFamily,
                    fontSize: 9,
                    letterSpacing: 1,
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Text(
                'Dhaka, BD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.film,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(advisory.icon, size: 14, color: advisory.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  advisory.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: advisory.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Turns the current condition into an actionable shoot advisory — "what to
  /// do" — biased toward outdoor shoots when one is scheduled today.
  ({String text, IconData icon, Color color}) _weatherAdvisory(
    String condition,
    bool hasOutdoorToday,
  ) {
    switch (condition) {
      case 'MOSTLY SUNNY':
        return hasOutdoorToday
            ? (
                text:
                    'Perfect for the outdoor shoot — carry a diffuser for harsh sun.',
                icon: Icons.wb_sunny_outlined,
                color: AppColors.green,
              )
            : (
                text: 'Great light for outdoor shoots right now.',
                icon: Icons.wb_sunny_outlined,
                color: AppColors.green,
              );
      case 'PARTLY CLOUDY':
        return (
          text:
              'Soft, even light — ideal for portraits. Keep a rain cover handy.',
          icon: Icons.wb_cloudy_outlined,
          color: AppColors.teal,
        );
      case 'MORNING SUN':
        return (
          text: 'Golden morning light — best window for outdoor frames.',
          icon: Icons.wb_twilight_outlined,
          color: AppColors.gold,
        );
      case 'EVENING':
        return (
          text: 'Golden hour — shoot now, then switch to lights after dusk.',
          icon: Icons.wb_twilight_outlined,
          color: AppColors.orange,
        );
      case 'CLEAR NIGHT':
        return (
          text: 'Clear night — plan lighting for any night shoot.',
          icon: Icons.nightlight_outlined,
          color: AppColors.indigo,
        );
      default:
        return (
          text: 'Check the sky before an outdoor shoot.',
          icon: Icons.info_outline,
          color: AppColors.filmDim,
        );
    }
  }

  // ─── Drawer ────────────────────────────────────────────────────────
  Widget _buildSidebar(UserModel? user) {
    final policy = RolePolicy(user?.role ?? UserRole.owner);
    final initials = user?.avatarInitials ?? '..';
    final name = user?.name ?? 'Welcome';
    final headerLine =
        '${(user?.role ?? UserRole.owner).displayLabel} · ${user?.studioLabel.split(' · ').last ?? 'Clicker Pro'}';

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 260,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.glassBorder, width: 1),
          ),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _pushNamed(RouteNames.profile);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 18),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    border: Border(
                      bottom: BorderSide(color: AppColors.line(0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (_) {
                          final image = _avatarImage(user?.avatarUrl);
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: image == null ? AppColors.accent : null,
                              border: Border.all(
                                color: AppColors.line(0.15),
                                width: 2,
                              ),
                              image: image == null
                                  ? null
                                  : DecorationImage(
                                      image: image,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: image != null
                                ? null
                                : Text(
                                    initials,
                                    style: TextStyle(
                                      fontFamily: AppText.brand.fontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.onAccent,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: AppText.brand.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.film,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              headerLine.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppText.sectionTitle.fontFamily,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                color: AppColors.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.filmDim.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  _sbGroup('MAIN'),
                  _sbItem(
                    Icons.home_outlined,
                    'Dashboard',
                    () => Navigator.pop(context),
                  ),
                  _sbItem(Icons.tune_outlined, 'Customize Dashboard', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.dashboardCustomize);
                  }),
                  _sbItem(Icons.calendar_month_outlined, 'Calendar', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.calendar);
                  }),
                  _sbItem(Icons.event_note_outlined, 'Bookings', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.bookings);
                  }),
                  if (policy.can(Capability.requestReEdit))
                    _sbItem(Icons.edit_note_outlined, 'Re-edit Requests', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.reEditRequests);
                    }),
                  _sbItem(Icons.chat_bubble_outline, 'Team Chat', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.chat);
                  }),
                  if (policy.can(Capability.accessTeam))
                    _sbItem(Icons.people_outline, 'Team & Staff', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.team);
                    }),
                  if (policy.can(Capability.viewAnnouncements))
                    _sbItem(Icons.campaign_outlined, 'Announcements', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.announcements);
                    }),
                  _sbItem(Icons.cell_tower_outlined, 'Platform Updates', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.broadcasts);
                  }),
                  _sbGroup('FINANCE'),
                  _sbItem(Icons.payments_outlined, 'Payments', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.paymentEntry);
                  }),
                  if (policy.can(Capability.accessInvoice))
                    _sbItem(Icons.receipt_long_outlined, 'Invoices', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.invoice);
                    }),
                  _sbItem(Icons.money_off_outlined, 'Expenses', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.finance);
                  }),
                  _sbItem(Icons.bar_chart_outlined, 'Reports & Analytics', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.reports);
                  }),
                  _sbItem(Icons.insights_outlined, 'Performance', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.performance);
                  }),
                  if (policy.can(Capability.accessTax))
                    _sbItem(Icons.calculate_outlined, 'Tax / VAT (NBR)', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.finance);
                    }),
                  _sbItem(Icons.timeline_outlined, 'Cash Flow', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.cashFlow);
                  }),
                  // Petty Cash entry removed per feedback — it overlapped with
                  // Expenses (petty cash is treated as an expense in profit +
                  // cash flow). Expenses above is the single entry point.
                  _sbGroup('OPERATIONS'),
                  if (policy.can(Capability.accessDailyTasks))
                    _sbItem(Icons.task_alt, 'Daily Tasks', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.bookings);
                    }),
                  _sbItem(Icons.camera_alt_outlined, 'Gear & Equipment', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.gear);
                  }),
                  if (policy.can(Capability.accessRentTracking))
                    _sbItem(Icons.swap_horiz, 'Rent Tracking', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.rent);
                    }),
                  if (policy.can(Capability.accessDelivery))
                    _sbItem(
                      Icons.local_shipping_outlined,
                      'Delivery',
                      () {
                        Navigator.pop(context);
                        _pushNamed(RouteNames.delivery);
                      },
                    ),
                  if (policy.can(Capability.accessPackages))
                    _sbItem(Icons.inventory_2_outlined, 'Packages', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.packages);
                    }),
                  if (policy.can(Capability.accessFollowup))
                    _sbItem(
                      Icons.follow_the_signs_outlined,
                      'Client Follow-up',
                      () {
                        Navigator.pop(context);
                        _pushNamed(RouteNames.followup);
                      },
                    ),
                  if (policy.can(Capability.accessReminders))
                    _sbItem(Icons.alarm_outlined, 'Reminders', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.reminders);
                    }),
                  if (policy.can(Capability.accessWaitlist))
                    _sbItem(Icons.hourglass_empty_outlined, 'Waitlist', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.waitlist);
                    }),
                  _sbItem(Icons.home_outlined, 'Home Widget', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.widgetSettings);
                  }),
                  _sbItem(Icons.calendar_month_outlined, 'Calendar Sync', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.calendarSyncSettings);
                  }),
                  if (policy.can(Capability.editGearInventory)) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      color: AppColors.line(0.05),
                    ),
                    _sbGroup('FREELANCER'),
                    _sbItem(Icons.beach_access_outlined, 'Leave Request', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.freelancerLeave);
                    }),
                  ],
                  if (policy.can(Capability.viewFinancials)) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      color: AppColors.line(0.05),
                    ),
                    _sbGroup('ADMIN'),
                    _sbItem(Icons.history_edu_outlined, 'Audit Log', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.auditLog);
                    }),
                    _sbItem(Icons.bug_report_outlined, 'Crash Reports', () {
                      Navigator.pop(context);
                      _pushNamed(RouteNames.crashSettings);
                    }),
                  ],
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: AppColors.line(0.05),
                  ),
                  _sbGroup('ACCOUNT'),
                  // Profile, Security, Privacy, Terms and Help are all reachable
                  // from inside Settings (and Profile) — removed here per
                  // Heaven's request to stop the sidebar duplicating them. Only
                  // the Settings entry point and Logout stay for quick access.
                  _sbItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.settings);
                  }),
                  _sbItem(Icons.logout, 'Logout', () async {
                    Navigator.pop(context);
                    await _confirmLogout();
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line(0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clicker Pro',
                    style: TextStyle(
                      fontFamily: AppText.sectionTitle.fontFamily,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: AppColors.filmDim.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'v1.0',
                    style: TextStyle(
                      fontFamily: AppText.sectionTitle.fontFamily,
                      fontSize: 9,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
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

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Text(
          'Sign out of Clicker Pro?',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brand.fontFamily,
          ),
        ),
        content: Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(sessionControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  Widget _sbGroup(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppText.sectionTitle.fontFamily,
          fontSize: 9,
          letterSpacing: 1.8,
          color: AppColors.filmDim.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Per-module accent so every drawer icon carries its own colour —
  /// modern SaaS sidebars colour-code by domain, not one flat accent.
  Color _sbTintFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('payment') ||
        l.contains('invoice') ||
        l.contains('expense') ||
        l.contains('petty') ||
        l.contains('finance') ||
        l.contains('earning')) {
      return AppColors.green;
    }
    if (l.contains('booking') ||
        l.contains('calendar') ||
        l.contains('re-edit') ||
        l.contains('waitlist')) {
      return AppColors.indigo;
    }
    if (l.contains('team') || l.contains('chat') || l.contains('staff')) {
      return AppColors.gold;
    }
    if (l.contains('announce') ||
        l.contains('platform') ||
        l.contains('notification')) {
      return AppColors.red;
    }
    return AppColors.orange;
  }

  Widget _sbItem(IconData icon, String label, VoidCallback onTap) {
    final tint = _sbTintFor(label);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: tint, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.5, color: AppColors.film),
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom navigation ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        // Slim bar — 56px keeps icon + label readable while reclaiming
        // vertical space for content.
        height: 56,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line(0.06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.line(0.10),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _navTab(
              outlinedIcon: Icons.home_outlined,
              filledIcon: Icons.home_rounded,
              tint: AppColors.orange,
              label: 'Home',
              index: 0,
            ),
            _navTab(
              outlinedIcon: Icons.event_note_outlined,
              filledIcon: Icons.event_note_rounded,
              tint: AppColors.indigo,
              label: 'Booking',
              index: 1,
            ),
            _navFab(),
            _navTab(
              outlinedIcon: Icons.payments_outlined,
              filledIcon: Icons.payments_rounded,
              tint: AppColors.green,
              label: 'Finance',
              index: 3,
            ),
            _navTab(
              outlinedIcon: Icons.settings_outlined,
              filledIcon: Icons.settings_rounded,
              tint: AppColors.gold,
              label: 'Settings',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTab({
    required IconData outlinedIcon,
    required IconData filledIcon,
    required Color tint,
    required String label,
    required int index,
  }) {
    final isActive = _selectedNavIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D-realistic icon chip: a gradient-filled rounded square with a
            // top highlight, a coloured outer glow and a soft drop shadow.
            // Active = full glossy chip; inactive = a flatter, dimmer tint so
            // the bar still reads colourful but the current tab clearly pops.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [
                          Color.lerp(tint, Colors.white, 0.30)!,
                          tint,
                          Color.lerp(tint, Colors.black, 0.18)!,
                        ]
                      : [
                          tint.withValues(alpha: 0.20),
                          tint.withValues(alpha: 0.12),
                        ],
                ),
                border: Border.all(
                  color: isActive
                      ? Color.lerp(
                          tint,
                          Colors.white,
                          0.35,
                        )!.withValues(alpha: 0.55)
                      : tint.withValues(alpha: 0.22),
                  width: 0.8,
                ),
                boxShadow: isActive
                    ? [
                        // Coloured outer glow — the "realistic" lift.
                        BoxShadow(
                          color: tint.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: -1,
                          offset: const Offset(0, 4),
                        ),
                        // Inner top highlight (gloss) faked with a light shadow.
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 1,
                          spreadRadius: -2,
                          offset: const Offset(0, -1),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedScale(
                  scale: isActive ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  // Active icon is white-on-gradient (reads as a glossy 3D
                  // button); inactive keeps the module colour on a soft tint.
                  child: Icon(
                    filledIcon,
                    color: isActive ? Colors.white : tint,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppText.body.fontFamily,
                fontSize: 10,
                letterSpacing: 0.1,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? tint : AppColors.filmDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNewBooking() => _pushNamed(RouteNames.bookingNew);

  Widget _navFab() {
    return Expanded(
      child: GestureDetector(
        onTap: _openNewBooking,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Glossy 3D orange button: light top-left → deep bottom-right.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(AppColors.accent, Colors.white, 0.30)!,
                  AppColors.accent,
                  Color.lerp(AppColors.accent, Colors.black, 0.20)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 2,
                  spreadRadius: -2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, color: AppColors.onAccent, size: 26),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Animated brand title — a one-shot fade + slide-in on mount. Uses a single
// TweenAnimationBuilder (no repeating controller), so it animates once and
// then stays static — zero ongoing cost.
// ─────────────────────────────────────────────────────────────────────

class _AnimatedBrand extends StatelessWidget {
  const _AnimatedBrand({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((1 - t) * -12, 0),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              // ClickerPro wordmark (spec): Hanken 800, tight tracking,
              // "Pro" in brand orange — NOT italic.
              style: TextStyle(
                fontFamily: AppText.brandFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.film,
                letterSpacing: -0.03 * 20,
              ),
              children: [
                const TextSpan(text: 'Graphy'),
                TextSpan(
                  text: '7',
                  style: TextStyle(color: AppColors.accent),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppText.body.fontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.filmDim.withValues(alpha: 0.85),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Announcement Card View ───────────────────────────────────────────────────

class _AnnouncementCardView extends StatelessWidget {
  const _AnnouncementCardView({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.pinned) ...[
                Icon(Icons.push_pin, size: 13, color: AppColors.gold),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PINNED',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                announcement.timeAgo,
                style: TextStyle(fontSize: 10, color: AppColors.filmDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.film,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            announcement.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.filmDim,
              height: 1.5,
            ),
          ),
          if (announcement.readCount > 0) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.line(0.06)),
            const SizedBox(height: 8),
            Text(
              '${announcement.readCount} read',
              style: TextStyle(fontSize: 10, color: AppColors.filmDim),
            ),
          ],
        ],
      ),
    );
  }
}

/// One "collection by source" row: a method icon + label with today's summed
/// amount, used in the Today Collection breakdown sheet.
class _CollectionSourceRow extends StatelessWidget {
  const _CollectionSourceRow({required this.method, required this.amount});

  final String method;
  final double amount;

  ({IconData icon, Color color, String label}) get _meta {
    switch (method) {
      case 'bkash':
        return (
          icon: Icons.phone_android_outlined,
          color: AppColors.purple,
          label: 'bKash',
        );
      case 'nagad':
        return (
          icon: Icons.phone_android_outlined,
          color: AppColors.orange,
          label: 'Nagad',
        );
      case 'bank':
        return (
          icon: Icons.account_balance_outlined,
          color: AppColors.teal,
          label: 'Bank',
        );
      case 'card':
        return (
          icon: Icons.credit_card_outlined,
          color: AppColors.indigo,
          label: 'Card',
        );
      case 'cash':
        return (
          icon: Icons.payments_outlined,
          color: AppColors.gold,
          label: 'Cash',
        );
      default:
        return (
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.filmDim,
          label: method.isEmpty
              ? 'Other'
              : method[0].toUpperCase() + method.substring(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(m.icon, color: m.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              m.label,
              style: TextStyle(
                color: AppColors.film,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            ActiveCurrency.value.wrap(amount.toStringAsFixed(0), spaced: true),
            style: TextStyle(
              color: AppColors.film,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
