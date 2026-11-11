import 'dart:io';

import 'package:http/http.dart' as http;

/// Deteksi error konektivitas jaringan untuk platform Mobile/Desktop (`dart:io`).
bool isNetworkConnectionError(Object error) {
  return error is SocketException || error is http.ClientException;
}
