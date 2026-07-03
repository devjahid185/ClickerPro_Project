// lib/features/admin/presentation/admin_home_screen.dart
//
// PRO ADMIN app's home — the only screen a logged-in admin lands on. Two
// tabs: platform Stats and Broadcasts management. No studio screens
// (bookings/finance/team) exist anywhere in this app by design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../profile/application/profile_controllers.dart';
import 'admin_login_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _tab == 0 ? 'Platform Stats' : 'Broadcasts',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
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
      body: IndexedStack(
        index: _tab,
        children: const [StatsTab(), BroadcastsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Broadcasts',
          ),
        ],
      ),
    );
  }
}
