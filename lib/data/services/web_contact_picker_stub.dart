/// Stub implementasi Web Contact Picker untuk platform non-web (Android/iOS/desktop).
bool isWebContactPickerSupported() => false;

Future<({String name, String rawPhone})?> pickWebContact() async {
  throw UnsupportedError('Web Contact Picker hanya tersedia di browser web.');
}
