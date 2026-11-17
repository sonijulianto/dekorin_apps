import 'package:material_ui/material_ui.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/error_log_service.dart';

/// Observer navigasi untuk mencatat screen aktif dan breadcrumbs ke [ErrorLogService].
class ErrorLogNavigatorObserver extends NavigatorObserver {
  void _record(Route<dynamic>? route, String action) {
    final name = route?.settings.name ?? route?.runtimeType.toString() ?? 'unknown';
    if (name.isEmpty) return;
    ErrorLogService.instance.currentRoute = name;
    ErrorLogService.instance.addBreadcrumb('nav', '$action -> $name');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _record(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _record(newRoute, 'replace');
    }
  }
}

/// Tampilan fallback ramah user menggantikan "layar merah" saat widget gagal dirender.
class ErrorFallbackWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const ErrorFallbackWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primaryGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ups, terjadi kendala tampilan',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Laporan error sudah otomatis tercatat untuk segera diperbaiki tim Dekorin.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
