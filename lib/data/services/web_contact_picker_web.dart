import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Memeriksa apakah browser mendukung Web Contact Picker API (`navigator.contacts.select`).
/// Saat ini didukung pada browser berbasis Chromium di Android (HTTPS).
bool isWebContactPickerSupported() {
  try {
    final nav = globalContext['navigator'];
    if (nav == null || nav.isUndefinedOrNull) return false;
    final navObj = nav as JSObject;
    if (!navObj.has('contacts')) return false;
    final contacts = navObj['contacts'];
    if (contacts == null || contacts.isUndefinedOrNull) return false;
    final contactsObj = contacts as JSObject;
    if (!contactsObj.has('select')) return false;
    final selectFn = contactsObj['select'];
    return selectFn != null && !selectFn.isUndefinedOrNull;
  } catch (_) {
    return false;
  }
}

/// Membuka pemilih kontak bawaan browser melalui `navigator.contacts.select`.
/// Mengembalikan `null` jika pengguna membatalkan pemilihan.
Future<({String name, String rawPhone})?> pickWebContact() async {
  if (!isWebContactPickerSupported()) {
    throw UnsupportedError('Pemilih kontak tidak didukung di browser ini.');
  }

  final navObj = globalContext['navigator'] as JSObject;
  final contactsObj = navObj['contacts'] as JSObject;

  final props = <JSString>['name'.toJS, 'tel'.toJS].toJS;
  final options = JSObject();
  options['multiple'] = false.toJS;

  final promise = contactsObj.callMethod<JSPromise<JSArray<JSObject>>>(
    'select'.toJS,
    props,
    options,
  );
  final result = (await promise.toDart).toDart;
  if (result.isEmpty) return null;

  final first = result.first;

  var name = '';
  if (first.has('name')) {
    final namesAny = first['name'];
    if (namesAny != null && !namesAny.isUndefinedOrNull) {
      final names = (namesAny as JSArray<JSString>).toDart;
      if (names.isNotEmpty) {
        name = names.first.toDart.trim();
      }
    }
  }

  var rawPhone = '';
  if (first.has('tel')) {
    final telsAny = first['tel'];
    if (telsAny != null && !telsAny.isUndefinedOrNull) {
      final tels = (telsAny as JSArray<JSString>).toDart;
      if (tels.isNotEmpty) {
        rawPhone = tels.first.toDart.trim();
      }
    }
  }

  return (name: name, rawPhone: rawPhone);
}
