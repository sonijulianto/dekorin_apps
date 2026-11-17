import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/app.dart';
import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/services/error_log_service.dart';
import 'package:dekorin_apps/data/services/push_notification_service.dart';
import 'package:dekorin_apps/ui/core/widgets/error_fallback_widget.dart';

void main() async {
  // Ensure flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences via DataPreferences
  await DataPreferences.init();

  // Initialize FE Error Logging & flush pending offline logs
  await ErrorLogService.instance.initialize();

  // Tangkap error UI/widget Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorLogService.instance.reportFlutterError(details);
  };

  // Tangkap uncaught async error di luar widget tree
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    ErrorLogService.instance.reportError(error, stack, level: 'fatal');
    return true;
  };

  // Tampilan fallback ramah user saat widget gagal build di release mode
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) => ErrorFallbackWidget(details: details);
  }

  // Initialize Firebase & Push Notifications (graceful fallback if unsupported)
  await PushNotificationService.instance.initialize();

  // Initialize locale data for Indonesian formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    // ProviderScope stores the state of all providers
    const ProviderScope(
      child: DekorinApp(),
    ),
  );
}
