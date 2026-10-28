import 'package:shared_preferences/shared_preferences.dart';

class DataPreferences {
  static late SharedPreferences _preferences;

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static const _token = "token";
  static const _user = "user"; // Menambahkan key untuk data user
  static const _invoiceTemplate = "invoice_template";

  static Future setToken(String token) async => await _preferences.setString(_token, token);
  static String getToken() => _preferences.getString(_token) ?? "";
  static bool isLoggedIn() => _preferences.getString(_token) != null;

  // Menyimpan dan mengambil JSON String dari data UserModel
  static Future setUser(String userJson) async => await _preferences.setString(_user, userJson);
  static String? getUser() => _preferences.getString(_user);

  // Template Invoice Pilihan User
  static Future<bool> setInvoiceTemplate(String templateId) async =>
      await _preferences.setString(_invoiceTemplate, templateId);
  static String getInvoiceTemplate() =>
      _preferences.getString(_invoiceTemplate) ?? "template_modern_navy";

  static Future<void> logout() async {
    await _preferences.remove(_token);
    await _preferences.remove(_user);
  }
}
