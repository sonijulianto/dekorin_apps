import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataPreferences {
  static late SharedPreferences _preferences;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? _cachedToken;

  static const _token = "token";
  static const _user = "user"; // Menambahkan key untuk data user
  static const _invoiceTemplate = "invoice_template";
  static const _aiDecorHistory = "ai_decor_history";

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();

    // 1. Coba baca token dari encrypted secure storage
    try {
      _cachedToken = await _secureStorage.read(key: _token);
    } catch (_) {
      _cachedToken = null;
    }

    // 2. Backward compatibility & Auto-migration:
    // Jika di secure storage belum ada token namun di SharedPreferences lama ada token plaintext
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      final legacyToken = _preferences.getString(_token);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        _cachedToken = legacyToken;
        try {
          await _secureStorage.write(key: _token, value: legacyToken);
        } catch (_) {}
        // Hapus token plaintext dari SharedPreferences setelah sukses migrasi
        await _preferences.remove(_token);
      }
    }
  }

  static Future setToken(String token) async {
    _cachedToken = token;
    try {
      await _secureStorage.write(key: _token, value: token);
    } catch (_) {}
    // Pastikan tidak ada token plaintext tertinggal di SharedPreferences
    await _preferences.remove(_token);
  }

  static String getToken() => _cachedToken ?? "";
  static bool isLoggedIn() => _cachedToken != null && _cachedToken!.isNotEmpty;

  // Menyimpan dan mengambil JSON String dari data UserModel
  static Future setUser(String userJson) async => await _preferences.setString(_user, userJson);
  static String? getUser() => _preferences.getString(_user);

  // Template Invoice Pilihan User
  static Future<bool> setInvoiceTemplate(String templateId) async =>
      await _preferences.setString(_invoiceTemplate, templateId);
  static String getInvoiceTemplate() =>
      _preferences.getString(_invoiceTemplate) ?? "template_modern_navy";

  // Riwayat Simulasi Warna Dekorasi AI
  static Future<bool> setAiDecorHistory(String historyJson) async =>
      await _preferences.setString(_aiDecorHistory, historyJson);
  static String? getAiDecorHistory() =>
      _preferences.getString(_aiDecorHistory);

  static Future<void> logout() async {
    _cachedToken = null;
    try {
      await _secureStorage.delete(key: _token);
    } catch (_) {}
    await _preferences.remove(_token);
    await _preferences.remove(_user);
  }
}
