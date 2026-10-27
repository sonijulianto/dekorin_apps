import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/models/app_version_info.dart';

class AppUpdateService {
  /// Mengambil info versi aplikasi dari server
  static Future<AppVersionInfo?> getLatestVersion() async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoint.appVersion}?platform=android',
        withToken: false,
      );

      if (response is Map && response['data'] != null) {
        return AppVersionInfo.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('AppUpdateService.getLatestVersion error: $e');
      return null;
    }
  }

  /// Mendapatkan build number aplikasi yang sedang berjalan
  static Future<int> getCurrentBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber) ?? 1;
    } catch (e) {
      debugPrint('Error getting current build number: $e');
      return 1;
    }
  }

  /// Mendapatkan version name aplikasi yang sedang berjalan (contoh: "1.0.0")
  static Future<String> getCurrentVersionName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      debugPrint('Error getting current version name: $e');
      return '1.0.0';
    }
  }
}
