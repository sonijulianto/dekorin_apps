import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';

/// Service terpusat untuk menangkap error FE (UI, async, API 5xx/parsing),
/// merekam breadcrumbs 10 aksi terakhir, deduplikasi 60 detik, dan antrean offline.
class ErrorLogService {
  ErrorLogService._();
  static final ErrorLogService instance = ErrorLogService._();

  static const String _pendingQueueKey = 'dekorin_pending_error_logs';
  static const int _maxPendingLogs = 20;
  static const int _maxBreadcrumbs = 10;
  static const Duration _dedupWindow = Duration(seconds: 60);

  /// Default hanya mengirim ke server saat Release mode agar log dev tidak mengotori production.
  bool enableInDebug = false;

  String currentRoute = '/';
  String _appVersion = '';
  bool _isFlushing = false;

  final List<Map<String, String>> _breadcrumbs = [];
  final Map<String, DateTime> _recentKeys = {};

  /// Inisialisasi versi aplikasi dan kirim ulang antrean log offline yang tertunda.
  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }
    unawaited(flushPendingLogs());
  }

  /// Mencatat jejak aksi terakhir (navigasi, API call, atau interaksi penting).
  void addBreadcrumb(String type, String message) {
    final entry = <String, String>{
      'time': DateTime.now().toIso8601String(),
      'type': type,
      'message': message.length > 200 ? message.substring(0, 200) : message,
    };
    _breadcrumbs.add(entry);
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Menangani error dari [FlutterError.onError].
  void reportFlutterError(FlutterErrorDetails details) {
    reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      level: 'error',
      extraContext: details.context?.toDescription(),
    );
  }

  /// Melaporkan error umum, async uncaught, atau API/parsing error.
  Future<void> reportError(
    Object error,
    StackTrace? stackTrace, {
    String level = 'error',
    Map<String, dynamic>? apiContext,
    String? extraContext,
  }) async {
    if (!kReleaseMode && !enableInDebug) {
      return;
    }

    try {
      final errorType = error.runtimeType.toString();
      final rawMessage = extraContext != null && extraContext.isNotEmpty
          ? '$error ($extraContext)'
          : error.toString();
      final errorMessage = _maskSensitive(rawMessage);
      final stackStr = stackTrace?.toString() ?? '';

      final dedupKey = '$level|$errorType|$currentRoute|${_firstLine(errorMessage)}';
      if (_isDuplicate(dedupKey)) {
        return;
      }

      final payload = <String, dynamic>{
        'level': level,
        'platform': _detectPlatform(),
        'app_version': _appVersion.isEmpty ? 'unknown' : _appVersion,
        'route': currentRoute,
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackStr,
        'breadcrumbs': List<Map<String, String>>.from(_breadcrumbs),
        'api_context': apiContext != null ? _maskApiContext(apiContext) : <String, dynamic>{},
        'device_info': _detectDeviceInfo(),
      };

      final sent = await _sendPayload(payload);
      if (!sent) {
        await _enqueuePending(payload);
      }
    } catch (_) {
      // Jangan pernah membiarkan ErrorLogService melempar exception
    }
  }

  /// Mengirim ulang log yang tersimpan di SharedPreferences saat sebelumnya offline.
  Future<void> flushPendingLogs() async {
    if ((!kReleaseMode && !enableInDebug) || _isFlushing) return;
    _isFlushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_pendingQueueKey) ?? [];
      if (rawList.isEmpty) return;

      final remaining = <String>[];
      for (var i = 0; i < rawList.length; i++) {
        final rawItem = rawList[i];
        try {
          final payload = jsonDecode(rawItem) as Map<String, dynamic>;
          final sent = await _sendPayload(payload);
          if (!sent) {
            remaining.addAll(rawList.sublist(i));
            break;
          }
        } catch (_) {
          // Abaikan item corrupt agar tidak menyumbat antrean
        }
      }
      await prefs.setStringList(_pendingQueueKey, remaining);
    } catch (_) {
    } finally {
      _isFlushing = false;
    }
  }

  Future<bool> _sendPayload(Map<String, dynamic> payload) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final token = DataPreferences.getToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(
            Uri.parse('${ApiEndpoint.baseUrl}${ApiEndpoint.clientLogs}'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enqueuePending(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingQueueKey) ?? [];
      list.add(jsonEncode(payload));
      if (list.length > _maxPendingLogs) {
        list.removeRange(0, list.length - _maxPendingLogs);
      }
      await prefs.setStringList(_pendingQueueKey, list);
    } catch (_) {}
  }

  bool _isDuplicate(String key) {
    final now = DateTime.now();
    _recentKeys.removeWhere((_, time) => now.difference(time) > _dedupWindow);
    final prev = _recentKeys[key];
    if (prev != null && now.difference(prev) <= _dedupWindow) {
      return true;
    }
    _recentKeys[key] = now;
    return false;
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _detectDeviceInfo() {
    if (kIsWeb) return 'Flutter Web (${defaultTargetPlatform.name})';
    return 'Flutter ${defaultTargetPlatform.name}';
  }

  String _firstLine(String text) {
    final idx = text.indexOf('\n');
    final line = idx == -1 ? text : text.substring(0, idx);
    return line.length > 100 ? line.substring(0, 100) : line;
  }

  String _maskSensitive(String input) {
    return input
        .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+', caseSensitive: false), 'Bearer [REDACTED]')
        .replaceAll(RegExp(r'"password"\s*:\s*"[^"]*"', caseSensitive: false), '"password":"[REDACTED]"');
  }

  Map<String, dynamic> _maskApiContext(Map<String, dynamic> ctx) {
    final copy = Map<String, dynamic>.from(ctx);
    if (copy['response_snippet'] is String) {
      final snippet = _maskSensitive(copy['response_snippet'] as String);
      copy['response_snippet'] = snippet.length > 500 ? snippet.substring(0, 500) : snippet;
    }
    return copy;
  }
}
