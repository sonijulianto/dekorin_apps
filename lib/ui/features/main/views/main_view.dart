import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    const activeNavColor = Color(0xFFB3854B);
    const inactiveNavColor = Color(0xFF7A7A7A);

    // Menentukan daftar icon navigasi bawah
    final List<BottomNavigationBarItem> navItems = isOwner
        ? [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.dashboard_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.dashboard_rounded, size: 24),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(inactiveNavColor, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(activeNavColor, BlendMode.srcIn),
                ),
              ),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(inactiveNavColor, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(activeNavColor, BlendMode.srcIn),
                ),
              ),
              label: 'Profile',
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(inactiveNavColor, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(activeNavColor, BlendMode.srcIn),
                ),
              ),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(inactiveNavColor, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(activeNavColor, BlendMode.srcIn),
                ),
              ),
              label: 'Profile',
            ),
          ];

    // Mencegah index out of bounds jika beralih akun/role
    final currentIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return GestureDetector(
      // Tutup keyboard ketika tap di mana pun di luar field input
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        body: pages[currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: activeNavColor,
              unselectedItemColor: inactiveNavColor,
              selectedLabelStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: activeNavColor,
              ),
              unselectedLabelStyle: AppTypography.labelMedium.copyWith(
                color: inactiveNavColor,
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
