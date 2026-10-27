import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/ui/core/widgets/app_update_dialog.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_view.dart';
import 'package:dekorin_apps/ui/features/dashboard/views/dashboard_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/profile/views/profile_view.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateChecker.check(context);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(globalAuthProvider).value;
    final isOwner = user?.canAccessDashboard ?? true;

    // Menentukan daftar halaman berdasarkan role:
    // Owner: [Dashboard, Agenda, Profile]
    // Admin & Crew: [Agenda, Profile] (Dashboard disembunyikan)
    final List<Widget> pages = isOwner
        ? const [
            DashboardView(),
            AgendaView(),
            ProfileView(),
          ]
        : const [
            AgendaView(),
            ProfileView(),
          ];

    // Menentukan daftar icon navigasi bawah
    final List<BottomNavigationBarItem> navItems = isOwner
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

    // Mencegah index out of bounds jika beralih akun/role
    final currentIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return GestureDetector(
      // Tutup keyboard ketika tap di mana pun di luar field input
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppTheme.primaryGold,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.labelMedium,
          backgroundColor: Colors.white,
          elevation: 10,
          items: navItems,
        ),
      ),
    );
  }
}
