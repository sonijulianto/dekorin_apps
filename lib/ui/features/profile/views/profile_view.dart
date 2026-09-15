import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(globalAuthProvider).value;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: AppTheme.primaryGold),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Profile',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? 'Pengaturan akan hadir di sini.'),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(globalAuthProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
