import 'package:http/http.dart' as http;

/// Deteksi error konektivitas jaringan untuk platform Web (tanpa `dart:io`).
bool isNetworkConnectionError(Object error) {
  return error is http.ClientException;
}
