import 'package:flutter/foundation.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactPickerServiceProvider = Provider<ContactPickerService>((ref) {
  return ContactPickerService();
});

/// Data kontak yang dipilih dari daftar kontak perangkat.
class PickedPhoneContact {
  const PickedPhoneContact({
    required this.name,
    required this.phoneNumber,
  });

  final String name;
  final String phoneNumber;
}

/// Service untuk memilih nomor HP klien dari aplikasi kontak bawaan perangkat.
class ContactPickerService {
  ContactPickerService({FlutterNativeContactPicker? picker})
      : _hasCustomPicker = picker != null,
        _picker = picker ?? FlutterNativeContactPicker();

  final bool _hasCustomPicker;
  final FlutterNativeContactPicker _picker;

  /// Membuka pemilih kontak bawaan (Android/iOS) untuk memilih satu nomor HP.
  /// Mengembalikan `null` jika pengguna membatalkan pemilihan atau di browser Web.
  Future<PickedPhoneContact?> pickPhoneContact() async {
    if (kIsWeb && !_hasCustomPicker) {
      throw UnsupportedError('Pemilih kontak tidak tersedia di browser.');
    }
    final contact = await _picker.selectPhoneNumber();
    if (contact == null) return null;

    final selected = contact.selectedPhoneNumber?.trim() ?? '';
    final fallback = (contact.phoneNumbers?.isNotEmpty == true)
        ? contact.phoneNumbers!.first.trim()
        : '';
    final rawPhone = selected.isNotEmpty ? selected : fallback;

    return PickedPhoneContact(
      name: (contact.fullName ?? '').trim(),
      phoneNumber: normalizePhoneNumber(rawPhone),
    );
  }

  /// Membersihkan format nomor kontak (spasi, tanda hubung, karakter tak terlihat)
  /// serta menormalkan awalan `+62` / `62` menjadi format lokal `0...`.
  static String normalizePhoneNumber(String raw) {
    final stripped = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (stripped.isEmpty) return '';

    final hasLeadingPlus = stripped.startsWith('+');
    final digits = stripped.replaceAll('+', '');
    if (digits.isEmpty) return '';

    if (hasLeadingPlus) {
      if (digits.startsWith('62')) {
        final rest = digits.substring(2);
        if (rest.isEmpty) return '';
        return rest.startsWith('0') ? rest : '0$rest';
      }
      return '+$digits';
    }

    if (digits.startsWith('62') && digits.length >= 10) {
      final rest = digits.substring(2);
      return rest.startsWith('0') ? rest : '0$rest';
    }

    return digits;
  }
}
