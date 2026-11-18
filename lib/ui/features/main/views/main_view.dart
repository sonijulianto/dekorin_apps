import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/chat_service.dart';
import 'package:dekorin_apps/data/services/push_notification_service.dart';
import 'package:dekorin_apps/ui/core/widgets/app_update_dialog.dart';
import 'package:dekorin_apps/ui/features/agenda/utils/agenda_category_config.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/chat_inbox_view.dart';
import 'package:dekorin_apps/ui/features/ai_studio/views/ai_decor_studio_view.dart';
import 'package:dekorin_apps/ui/features/couple/views/couple_invitation_view.dart';
import 'package:dekorin_apps/ui/features/couple/views/couple_planner_view.dart';
import 'package:dekorin_apps/ui/features/couple/views/couple_vendors_view.dart';
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
      ref.read(invoiceTemplateProvider.notifier).syncFromServer();
      PushNotificationService.instance.consumePendingNotificationTap();
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
    final isCouple = user?.isCouple ?? false;
    final isOwner = user?.canAccessDashboard ?? true;
    final isDecorationCompany = AgendaCategoryConfig.fromCategory(user?.companyCategory ?? 'decoration').isDecoration;
    final canUseAiStudio = (user?.canUseAiStudio ?? true) && isDecorationCompany;
    final totalChatUnread = !isCouple
        ? (ref.watch(chatUnreadSummaryProvider).valueOrNull?.totalUnread ?? 0)
        : 0;

    const activeNavColor = Color(0xFFB3854B);
    const inactiveNavColor = Color(0xFF7A7A7A);

    // Menentukan daftar halaman & item navigasi bawah berdasarkan role:
    // - Couple: [Planner, Vendor, Undangan, Profil]
    // - Owner:  [Dashboard, Agenda, Diskusi, Simulasi AI, Profile]
    // - Admin:  [Agenda, Diskusi, Simulasi AI, Profile]
    // - Crew:   [Agenda, Diskusi, Profile]
    final List<Widget> pages = isCouple
        ? [
            CouplePlannerView(onNavigateToTab: _onItemTapped),
            const CoupleVendorsView(),
            const CoupleInvitationView(),
            const ProfileView(),
          ]
        : [
            if (isOwner) const DashboardView(),
            const AgendaView(),
            const ChatInboxView(),
            if (canUseAiStudio) const AiDecorStudioView(),
            const ProfileView(),
          ];

    final List<BottomNavigationBarItem> navItems = isCouple
        ? [
            _buildSvgNavItem('assets/icons/calendar.svg', 'Planner', activeNavColor, inactiveNavColor),
            _buildSvgNavItem('assets/icons/wallet-income.svg', 'Vendor', activeNavColor, inactiveNavColor),
            _buildSvgNavItem('assets/icons/share.svg', 'Undangan', activeNavColor, inactiveNavColor),
            _buildSvgNavItem('assets/icons/user.svg', 'Profil', activeNavColor, inactiveNavColor),
          ]
        : [
            if (isOwner)
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
            _buildSvgNavItem('assets/icons/calendar.svg', 'Agenda', activeNavColor, inactiveNavColor),
            _buildSvgNavItem(
              'assets/icons/chat-arrow-grow.svg',
              'Diskusi',
              activeNavColor,
              inactiveNavColor,
              badgeCount: totalChatUnread,
            ),
            if (canUseAiStudio)
              _buildSvgNavItem('assets/icons/ai-magic.svg', 'Simulasi AI', activeNavColor, inactiveNavColor),
            _buildSvgNavItem('assets/icons/user.svg', 'Profile', activeNavColor, inactiveNavColor),
          ];

    // Mencegah index out of bounds jika beralih akun/role
    final currentIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return GestureDetector(
      // Tutup keyboard ketika tap di mana pun di luar field input
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
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

  BottomNavigationBarItem _buildSvgNavItem(
    String assetPath,
    String label,
    Color activeColor,
    Color inactiveColor, {
    int badgeCount = 0,
  }) {
    Widget buildIcon(Color color) {
      final svg = SvgPicture.asset(
        assetPath,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
      if (badgeCount <= 0) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: svg,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            svg,
            Positioned(
              right: -8,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BottomNavigationBarItem(
      icon: buildIcon(inactiveColor),
      activeIcon: buildIcon(activeColor),
      label: label,
    );
  }
}
