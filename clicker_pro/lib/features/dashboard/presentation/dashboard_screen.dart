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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/bd_holidays.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/notifications/event_reminder_service.dart';
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
import '../../../core/booking_status/booking_status.dart';
import '../../bookings/application/booking_providers.dart';
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
      // "1 hour before" alarms can be scheduled (fail-soft).
      EventReminderService.instance.init();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
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
        // Freelancer's "Finance" is their earnings view — they have no
        // studio income/expense data to show.
        final role = ref.read(currentUserProvider).valueOrNull?.role;
        _pushNamed(
          role == UserRole.freelancer
              ? RouteNames.freelancerEarnings
              : RouteNames.finance,
        );
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

  // ─── Build ──────────────────────────────────────────────────────────
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

    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(user),
      drawer: _buildSidebar(user),
      body: Column(
        children: [
          // Network indicator — invisible when online (zero-height).
          const OfflineBanner(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
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
      bottomNavigationBar: _buildBottomNav(),
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
          child: _avatarButton(initials, user?.id),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
    );
  }

  Widget _avatarButton(String initials, String? userId) {
    final avatar = Material(
      child: InkWell(
        onTap: () => _pushNamed(RouteNames.profile),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.12),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: AppText.brand.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
    if (userId == null) return avatar;
    return Hero(tag: 'user-avatar-$userId', child: avatar);
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: List.generate(days.length, (int i) {
          final d = days[i];
          final isToday = _isSameDay(d, today);
          final isSelected = _isSameDay(d, selected);
          final hasEvent = i == 0 || i == 3;

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
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                )
              : null;

          final Color labelColor = isToday
              ? Colors.white
              : AppColors.filmDim.withValues(alpha: 0.65);
          final Color numColor = isToday ? Colors.white : AppColors.film;

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
                                color: isToday ? Colors.white : AppColors.teal,
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Big today count card ──
            Expanded(
              child: GestureDetector(
                onTap: () => _pushNamed(RouteNames.bookings),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.teal,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('today_events'),
                            style: TextStyle(
                              fontFamily: AppText.body.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.filmDim,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _twoDigit(m.todayEvents),
                          key: ValueKey('hero-today-${m.todayEvents}'),
                          style: TextStyle(
                            fontFamily: AppText.brand.fontFamily,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                            height: 1.0,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _dayNightPill(
                            label: 'Day',
                            count: dayNight.$1,
                            color: AppColors.yellow,
                          ),
                          const SizedBox(width: 6),
                          _dayNightPill(
                            label: 'Night',
                            count: dayNight.$2,
                            color: AppColors.indigo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Right: Upcoming + Total stacked ──
            Expanded(
              child: Column(
                children: [
                  _miniHeroCard(
                    title: 'Upcoming',
                    value: '${m.upcomingEvents}',
                    color: AppColors.gold,
                    onTap: () => _pushNamed(RouteNames.bookings),
                  ),
                  const SizedBox(height: 10),
                  _miniHeroCard(
                    title: 'Total',
                    value: '${m.totalEvents}',
                    color: AppColors.indigo,
                    onTap: () => _pushNamed(RouteNames.bookings),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dayNightPill({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontFamily: AppText.body.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _miniHeroCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppText.body.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.filmDim,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                value,
                key: ValueKey('mini-hero-$title-$value'),
                style: TextStyle(
                  fontFamily: AppText.brand.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.0,
                  letterSpacing: -0.6,
                ),
              ),
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      child: ErrorState(
        message: 'Failed to load',
        onRetry: () => ref.invalidate(dashboardMetricsProvider),
      ),
    );
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
        ),
        child: const LensLoader(size: 22),
      ),
      error: (_, stack) => const SizedBox.shrink(),
      data: (m) => GestureDetector(
        onTap: () => _pushNamed(RouteNames.bookings),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivered',
                    style: TextStyle(
                      fontFamily: AppText.body.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.filmDim,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.successEvents}',
                    style: TextStyle(
                      fontFamily: AppText.brand.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Mini horizontal bar chart
              _miniBarChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBarChart() {
    // Static mini bar chart — 4 bars of varying heights, green/teal tones.
    final bars = [
      (h: 12.0, c: AppColors.green.withValues(alpha: 0.5)),
      (h: 20.0, c: AppColors.teal.withValues(alpha: 0.6)),
      (h: 16.0, c: AppColors.green.withValues(alpha: 0.7)),
      (h: 24.0, c: AppColors.green),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars
          .map(
            (b) => Container(
              width: 6,
              height: b.h,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: b.c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )
          .toList(),
    );
  }

  String _twoDigit(int v) => v < 10 ? '0$v' : '$v';

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
  // Owner/Both/Manager: Calendar · Invoice · Chat · Team
  // Freelancer: Calendar · Company · Chat · Expense
  Widget _buildQuickActions(UserModel? user) {
    final isFreelancer = user?.role == UserRole.freelancer;
    return Row(
      children: [
        _qaBtn(
          icon: Icons.calendar_month_rounded,
          color: AppColors.accent,
          label: t('btn_calendar'),
          routeName: RouteNames.calendar,
        ),
        _qaBtn(
          icon: isFreelancer
              ? Icons.business_rounded
              : Icons.receipt_long_rounded,
          color: AppColors.gold,
          label: isFreelancer ? 'Company' : t('btn_invoice'),
          routeName: isFreelancer ? RouteNames.profile : RouteNames.invoice,
        ),
        _qaBtn(
          icon: Icons.chat_bubble_rounded,
          color: AppColors.indigo,
          label: t('btn_chat'),
          routeName: RouteNames.chat,
        ),
        _qaBtn(
          icon: isFreelancer
              ? Icons.account_balance_wallet_rounded
              : Icons.people_rounded,
          color: AppColors.green,
          label: isFreelancer ? 'Expense' : t('btn_team'),
          routeName: isFreelancer ? RouteNames.finance : RouteNames.team,
        ),
      ],
    );
  }

  Widget _qaBtn({
    required IconData icon,
    required Color color,
    required String label,
    required String routeName,
  }) {
    return Expanded(
      child: TapScale(
        onTap: () => _pushNamed(routeName),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
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
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                child: const Icon(
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
          return placeholderBox(
            'No announcements yet — tap to post one.',
          );
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
              sub: 'today',
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
            sub: 'today',
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
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Events with outstanding due',
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: 'Poppins',
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
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
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
                                child: const Icon(
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
                                '৳${e.due.toStringAsFixed(0)}',
                                style: const TextStyle(
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
    // Compact BDT formatter for tile display. minor units = paisa.
    final taka = (minor / 100).round();
    final s = taka.toString();
    // Bangladesh-style grouping (last 3, then 2-2-…). Simple version:
    final buf = StringBuffer();
    final reversed = s.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
      buf.write(reversed[i]);
    }
    return '৳${buf.toString().split('').reversed.join()}';
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '🎉 ${DateFormat.MMMM().format(now)} — holidays this month',
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: 'Poppins',
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
                            style: const TextStyle(
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

  /// Opens the booking list showing ONLY cancelled events.
  void _openCancelledEvents() {
    ref.read(bookingFilterProvider.notifier).state = ref
        .read(bookingFilterProvider)
        .copyWith(statuses: {BookingStatus.cancelled});
    _pushNamed(RouteNames.bookings);
  }

  Widget _buildInfoCard({
    required String emoji,
    required String number,
    required String label,
    required bool isCancel,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                    fontFamily: AppText.brand.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isCancel ? AppColors.red : AppColors.film,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppText.sectionTitle.fontFamily,
                  fontSize: 10,
                  letterSpacing: 0.5,
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

  // ─── Weather card (visual unchanged) ───────────────────────────────
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
    // Compact one-line strip — the old oversized emoji + 30px temperature
    // crowded the column and collided with neighbouring sections.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
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
    );
  }

  // ─── Drawer ────────────────────────────────────────────────────────
  Widget _buildSidebar(UserModel? user) {
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
          border: Border(right: BorderSide(color: AppColors.glassBorder, width: 1)),
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
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontFamily: AppText.brand.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
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
                  _sbItem(Icons.edit_note_outlined, 'Re-edit Requests', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.reEditRequests);
                  }),
                  _sbItem(Icons.chat_bubble_outline, 'Team Chat', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.chat);
                  }),
                  _sbItem(Icons.people_outline, 'Team & Staff', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.team);
                  }),
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
                  _sbItem(Icons.calculate_outlined, 'Tax / VAT (NBR)', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.finance);
                  }),
                  _sbItem(Icons.timeline_outlined, 'Cash Flow', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.cashFlow);
                  }),
                  _sbItem(Icons.receipt_long_outlined, 'Petty Cash Book', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.pettyCash);
                  }),
                  _sbGroup('OPERATIONS'),
                  _sbItem(Icons.task_alt, 'Daily Tasks', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.bookings);
                  }),
                  _sbItem(Icons.camera_alt_outlined, 'Gear & Equipment', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.gear);
                  }),
                  _sbItem(Icons.swap_horiz, 'Rent Tracking', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.rent);
                  }),
                  _sbItem(Icons.local_shipping_outlined, 'Delivery System', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.bookings);
                  }),
                  _sbItem(Icons.inventory_2_outlined, 'Packages', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.packages);
                  }),
                  _sbItem(Icons.follow_the_signs_outlined, 'Client Follow-up', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.followup);
                  }),
                  _sbItem(Icons.alarm_outlined, 'Reminders', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.reminders);
                  }),
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
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  _sbGroup('FREELANCER'),
                  _sbItem(Icons.account_balance_wallet_outlined, 'My Earnings', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerEarnings);
                  }),
                  _sbItem(Icons.military_tech_outlined, 'My Badges', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerBadges);
                  }),
                  _sbItem(Icons.event_available_outlined, 'My Availability', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerAvailability);
                  }),
                  _sbItem(Icons.login_outlined, 'Check-In', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerCheckin);
                  }),
                  _sbItem(Icons.beach_access_outlined, 'Leave Request', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerLeave);
                  }),
                  _sbItem(Icons.history_outlined, 'Work History', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.freelancerWorkHistory);
                  }),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  _sbGroup('ADMIN'),
                  _sbItem(Icons.backup_outlined, 'Backup & Restore', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.backup);
                  }),
                  _sbItem(Icons.history_edu_outlined, 'Audit Log', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.auditLog);
                  }),
                  _sbItem(Icons.bug_report_outlined, 'Crash Reports', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.crashSettings);
                  }),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  _sbGroup('ACCOUNT'),
                  _sbItem(Icons.person_outline, 'Profile', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.profile);
                  }),
                  _sbItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.settings);
                  }),
                  _sbItem(Icons.security_outlined, 'Security', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.securitySettings);
                  }),
                  _sbItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.privacy);
                  }),
                  _sbItem(Icons.description_outlined, 'Terms of Service', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.terms);
                  }),
                  _sbItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.pop(context);
                    _pushNamed(RouteNames.help);
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
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
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
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
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
            // Active pill is drawn ONLY when active to keep inactive lean.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isActive ? 32 : 24,
              height: 22,
              decoration: BoxDecoration(
                color: isActive
                    ? tint.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                // A small spring-scale on the active icon gives the tab a
                // lively tap response without any repeating animation.
                child: AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  // Always-colourful tabs: filled icons in each module's
                  // own colour (inactive just slightly softened) — the old
                  // grey-washed inactive state read as monochrome.
                  child: Icon(
                    filledIcon,
                    color: isActive ? tint : tint.withValues(alpha: 0.75),
                    size: 19,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppText.body.fontFamily,
                fontSize: 10,
                letterSpacing: 0.1,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
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
              style: TextStyle(
                fontFamily: AppText.brand.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.film,
              ),
              children: const [
                TextSpan(text: 'Clicker '),
                TextSpan(
                  text: 'Pro',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontStyle: FontStyle.italic,
                  ),
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
                const Icon(Icons.push_pin, size: 13, color: AppColors.gold),
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
                  child: const Text(
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
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.filmDim,
                ),
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
            Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            Text(
              '${announcement.readCount} read',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.filmDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
