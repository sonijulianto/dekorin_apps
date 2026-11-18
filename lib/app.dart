import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/services/chat_service.dart';
import 'package:dekorin_apps/data/services/collaboration_service.dart';
import 'package:dekorin_apps/data/services/push_notification_service.dart';
import 'package:dekorin_apps/ui/core/widgets/error_fallback_widget.dart';
import 'package:dekorin_apps/ui/core/widgets/web_mobile_shell.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_chat_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/collaboration_invitations_view.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.onNotificationReceived = () {
      if (!mounted) return;
      ref.invalidate(incomingCollaborationsProvider);
      ref.invalidate(chatUnreadSummaryProvider);
      ref.invalidate(chatRoomsProvider);
    };
    PushNotificationService.instance.onNotificationTap = (data) {
      if (!mounted) return;
      final user = ref.read(globalAuthProvider).value;
      if (user == null) return;
      final type = (data['type'] ?? '').toString();
      if (type == 'agenda_chat') {
        final agendaId = (data['lead_agenda_id'] ?? data['reference_id'] ?? '').toString();
        if (agendaId.isNotEmpty) {
          ref.invalidate(chatUnreadSummaryProvider);
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AgendaChatView(agendaId: agendaId),
            ),
          );
        }
        return;
      }
      if (type.isEmpty || type.startsWith('collaboration_')) {
        ref.invalidate(incomingCollaborationsProvider);
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const CollaborationInvitationsView(),
          ),
        );
      }
    };
    // Daftarkan listener 401: otomatis logout dan beri notifikasi ramah
    ApiClient.onUnauthorized = () {
      ref.read(globalAuthProvider.notifier).forceLogout();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Sesi Anda telah berakhir. Silakan masuk kembali.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
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
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorObservers: [ErrorLogNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Tutup keyboard secara global ketika user tap di area kosong mana pun
      // dan pusatkan ke frame mobile saat dibuka di browser desktop.
      builder: (context, child) => WebMobileShell(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: authState.when(
        data: (user) {
          // Jika ada user (berhasil login/auto-login), ke MainView.
          // Jika null (belum login / habis logout), ke LoginView.
          if (user != null) {
            return const MainView();
          }
          return const LoginView();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => const LoginView(), // fallback ke login jika ada error
      ),
    );
  }
}
