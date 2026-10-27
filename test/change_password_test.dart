import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/repositories/auth_repository_impl.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/domain/repositories/auth_repository.dart';
import 'package:dekorin_apps/ui/features/profile/view_models/change_password_view_model.dart';
import 'package:dekorin_apps/ui/features/profile/views/change_password_view.dart';

class FakeAuthRepository implements AuthRepository {
  bool changePasswordCalled = false;
  String? lastCurrentPassword;
  String? lastNewPassword;
  bool shouldThrow = false;

  @override
  Future<User> login({
    required String phone,
    required String password,
    String? email,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldThrow) {
      throw Exception('Server error');
    }
    changePasswordCalled = true;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }
}

void main() {
  group('ChangePasswordViewModel', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has correct default values', () {
      final state = container.read(changePasswordViewModelProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
      expect(state.errorMessage, isNull);
      expect(state.isCurrentPasswordVisible, false);
      expect(state.isNewPasswordVisible, false);
      expect(state.isConfirmPasswordVisible, false);
    });

    test('toggle password visibilities works', () {
      final notifier = container.read(changePasswordViewModelProvider.notifier);

      notifier.toggleCurrentPasswordVisibility();
      expect(container.read(changePasswordViewModelProvider).isCurrentPasswordVisible, true);

      notifier.toggleNewPasswordVisibility();
      expect(container.read(changePasswordViewModelProvider).isNewPasswordVisible, true);

      notifier.toggleConfirmPasswordVisibility();
      expect(container.read(changePasswordViewModelProvider).isConfirmPasswordVisible, true);
    });

    test('fails when current password is empty', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: '',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );

      expect(result, false);
      expect(container.read(changePasswordViewModelProvider).errorMessage, 'Password saat ini wajib diisi');
      expect(fakeRepo.changePasswordCalled, false);
    });

    test('fails when new password is empty', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: 'oldpassword123',
        newPassword: '',
        confirmPassword: '',
      );

      expect(result, false);
      expect(container.read(changePasswordViewModelProvider).errorMessage, 'Password baru wajib diisi');
      expect(fakeRepo.changePasswordCalled, false);
    });

    test('fails when new password is shorter than 6 characters', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: 'oldpassword123',
        newPassword: '123',
        confirmPassword: '123',
      );

      expect(result, false);
      expect(container.read(changePasswordViewModelProvider).errorMessage, 'Password baru minimal 6 karakter');
      expect(fakeRepo.changePasswordCalled, false);
    });

    test('fails when new password is same as current password', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: 'password123',
        newPassword: 'password123',
        confirmPassword: 'password123',
      );

      expect(result, false);
      expect(
        container.read(changePasswordViewModelProvider).errorMessage,
        'Password baru tidak boleh sama dengan password saat ini',
      );
      expect(fakeRepo.changePasswordCalled, false);
    });

    test('fails when confirm password does not match new password', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: 'oldpassword123',
        newPassword: 'newpassword123',
        confirmPassword: 'differentpassword',
      );

      expect(result, false);
      expect(
        container.read(changePasswordViewModelProvider).errorMessage,
        'Konfirmasi password baru tidak cocok',
      );
      expect(fakeRepo.changePasswordCalled, false);
    });

    test('successfully changes password', () async {
      final notifier = container.read(changePasswordViewModelProvider.notifier);
      final result = await notifier.changePassword(
        currentPassword: 'oldpassword123',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );

      expect(result, true);
      final state = container.read(changePasswordViewModelProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, true);
      expect(state.errorMessage, isNull);
      expect(fakeRepo.changePasswordCalled, true);
      expect(fakeRepo.lastCurrentPassword, 'oldpassword123');
      expect(fakeRepo.lastNewPassword, 'newpassword123');
    });
  });

  group('ChangePasswordView Widget Tests', () {
    testWidgets('renders all fields and button properly', (WidgetTester tester) async {
      final fakeRepo = FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ChangePasswordView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi'), findsOneWidget);
      expect(find.text('Minimal terdiri dari 6 karakter'), findsOneWidget);
    });
  });
}

