import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter untuk memformat angka secara otomatis dengan pemisah ribuan titik (Indonesian format).
/// Contoh: mengetik "1000000" otomatis menjadi "1.000.000".
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Ambil hanya angka
    final cleanDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(cleanDigits);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
