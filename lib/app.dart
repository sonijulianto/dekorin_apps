import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/login/views/login_view.dart';
import 'package:dekorin_apps/ui/features/main/views/main_view.dart';

/// Root widget for the Dekorin application.
class DekorinApp extends ConsumerStatefulWidget {
  const DekorinApp({super.key});

  @override
  ConsumerState<DekorinApp> createState() => _DekorinAppState();
}

class _DekorinAppState extends ConsumerState<DekorinApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Daftarkan listener 401: otomatis logout dan beri notifikasi ramah
    ApiClient.onUnauthorized = () {
      ref.read(globalAuthProvider.notifier).forceLogout();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir. Silakan masuk kembali.'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(globalAuthProvider);

    return MaterialApp(
      title: 'Dekorin',
      scaffoldMessengerKey: _scaffoldMessengerKey,
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
