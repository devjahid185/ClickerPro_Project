// lib/features/admin/presentation/admin_home_screen.dart
//
// PRO ADMIN app's home — the only screen a logged-in admin lands on. Three
// tabs: platform Stats, Broadcasts management, and App Control. No studio
// screens (bookings/finance/team) exist anywhere in this app by design.
//
// Chrome follows the Graphy7 admin design: a mono eyebrow above the screen
// title, and a floating lime pill navigation bar with a raised center "+" FAB
// that composes a new broadcast (the one create action an admin actually has).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../profile/application/profile_controllers.dart';
import 'admin_login_screen.dart';
import 'widgets/admin_floating_nav.dart';
import 'widgets/app_control_tab.dart';
import 'widgets/broadcasts_tab.dart';
import 'widgets/stats_tab.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tab = 0;

  Future<void> _logout() async {
    await ref.read(sessionControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  /// Eyebrow + title shown per tab. The eyebrow is a mono, uppercase caption
  /// (Graphy7 admin design language); the title is the brand-weight heading.
  ({String eyebrow, String title}) get _header => switch (_tab) {
        0 => (eyebrow: 'PLATFORM · GRAPHY7', title: 'Platform Stats'),
        1 => (eyebrow: 'ANNOUNCEMENTS', title: 'Broadcasts'),
        _ => (eyebrow: 'CONFIGURATION', title: 'App Control'),
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final header = _header;

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        toolbarHeight: 66,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header.eyebrow,
              style: TextStyle(
                fontFamily: AppText.monoFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              header.title,
              style: TextStyle(
                color: AppColors.film,
                fontFamily: AppText.brandFontFamily,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  user.name,
                  style: TextStyle(color: AppColors.filmDim, fontSize: 13),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sign out',
            icon: Icon(Icons.logout_outlined, color: AppColors.filmDim),
            onPressed: _logout,
          ),
        ],
      ),
      // extendBody lets the floating pill nav hover over the content instead
      // of sitting on an opaque bar — the content scrolls behind it.
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          StatsTab(onOpenBroadcasts: () => setState(() => _tab = 1)),
          const BroadcastsTab(),
          const AppControlTab(),
        ],
      ),
      bottomNavigationBar: AdminFloatingNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onComposeBroadcast: () => BroadcastsTab.openComposer(context),
        items: const [
          AdminNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'STATS',
          ),
          AdminNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign,
            label: 'SENT',
          ),
          AdminNavItem(
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune,
            label: 'CONTROL',
          ),
        ],
      ),
    );
  }
}
