import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/login/views/login_view.dart';
import 'package:dekorin_apps/ui/features/main/views/main_view.dart';

/// Root widget for the Dekorin application.
class DekorinApp extends ConsumerWidget {
  const DekorinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(globalAuthProvider);

    return MaterialApp(
      title: 'Dekorin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          // Jika ada user (berhasil login/auto-login), ke MainView.
          // Jika null (belum login / habis logout), ke LoginView.
          if (user != null) {
            return const MainView();
          }
          return const LoginView();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => const LoginView(), // fallback ke login jika ada error
      ),
    );
  }
}
