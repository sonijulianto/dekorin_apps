import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/login/views/login_view.dart';
import 'package:dekorin_apps/ui/features/main/views/main_view.dart';
import 'package:dekorin_apps/ui/features/profile/views/profile_view.dart';

class _FakeCoupleAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'usr_couple_1',
      name: 'Bagas & Zulia',
      phone: '081234567890',
      role: 'couple',
      permissions: [],
    );
  }
}

void main() {
  group('Couple Role & Multi-Category Models', () {
    test('Couple user has restricted vendor permissions and proper role display name', () {
      const couple = User(
        id: 'usr_c1',
        name: 'Bagas',
        phone: '081234567890',
        role: 'couple',
        permissions: ['agenda.view'], // walau disisipkan, couple tetap tidak punya izin vendor
      );

      expect(couple.isCouple, isTrue);
      expect(couple.isVendor, isFalse);
      expect(couple.isOwner, isFalse);
      expect(couple.isAdmin, isFalse);
      expect(couple.canAccessDashboard, isFalse);
      expect(couple.canManageCompany, isFalse);
      expect(couple.canUseAiStudio, isFalse);
      expect(couple.can('agenda.view'), isFalse);
      expect(couple.roleDisplayName, 'Calon Pengantin');
    });

    test('CompanyProfile defensive fromJson handles category, city, and public listing', () {
      final fallbackProfile = CompanyProfile.fromJson({'id': 'cmp_1', 'name': 'Vendor A'});
      expect(fallbackProfile.category, 'decoration');
      expect(fallbackProfile.city, '');
      expect(fallbackProfile.isPublicListed, isFalse);

      final parsed = CompanyProfile.fromJson({
        'id': 'cmp_2',
        'name': 'Aura MUA Studio',
        'category': 'mua',
        'city': 'Bandung',
        'is_public_listed': true,
      });
      expect(parsed.category, 'mua');
      expect(parsed.city, 'Bandung');
      expect(parsed.isPublicListed, isTrue);
      expect(VendorCategoryOption.byId(parsed.category).shortLabel, 'MUA');
    });

    test('WeddingPlanDetail, WeddingPlanVendorItem, and WeddingTaskItem parse defensively', () {
      final detail = WeddingPlanDetail.fromJson({
        'plan': {
          'id': 'wp_1',
          'title': 'Pernikahan Bagas & Zulia',
          'groom_name': 'Bagas',
          'bride_name': 'Zulia',
          'wedding_date': '2026-12-20',
          'budget_target': 75000000,
          'join_code': 'AB12CD34',
        },
        'members': [
          {'user_id': 'u1', 'full_name': 'Bagas', 'phone': '08123', 'member_role': 'creator'},
        ],
        'stats': {
          'days_remaining': 39,
          'total_tasks': 10,
          'completed_tasks': 4,
          'total_vendors': 3,
          'total_agreed_cost': 25000000,
          'total_dp_paid': 5000000,
          'remaining_vendor_balance': 20000000,
          'total_pax_hadir': 120,
        },
      });

      expect(detail.plan.joinCode, 'AB12CD34');
      expect(detail.members.length, 1);
      expect(detail.stats.daysRemaining, 39);
      expect(detail.stats.taskProgress, closeTo(0.4, 0.001));

      final vendor = WeddingPlanVendorItem.fromJson({
        'id': 'wpv_1',
        'vendor_name': 'Mahakarya Dekorasi',
        'vendor_category': 'decoration',
        'agreed_price': 15000000,
        'dp_paid': 3000000,
        'is_synced_agenda': true,
      });
      expect(vendor.remainingBalance, 12000000);
      expect(vendor.isSyncedAgenda, isTrue);

      final task = WeddingTaskItem.fromJson({'id': 'wt_1', 'title': 'Booking Venue', 'is_completed': null});
      expect(task.isCompleted, isFalse);
      expect(task.copyWith(isCompleted: true).isCompleted, isTrue);
    });
  });

  group('Couple UI Role Routing & Views', () {
    testWidgets('LoginView includes Register Couple button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Daftar sebagai Calon Pengantin'), findsOneWidget);
    });

    testWidgets('ProfileView renders Couple header and hides vendor sections', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _FakeCoupleAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dekorin Wedding Plan'), findsOneWidget);
      expect(find.text('Calon Pengantin'), findsOneWidget);
      expect(find.text('PENGATURAN USAHA & BISNIS'), findsNothing);
      expect(find.text('MASTER DATA DEKORASI'), findsNothing);
      expect(find.text('MANAJEMEN TIM & KARYAWAN'), findsNothing);
    });

    testWidgets('MainView displays 4 Couple tabs when user role is couple', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _FakeCoupleAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Vendor'), findsOneWidget);
      expect(find.text('Undangan'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Agenda'), findsNothing);
    });
  });
}
