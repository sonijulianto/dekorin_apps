import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';

class InvoiceTemplateNotifier extends StateNotifier<InvoiceTemplate> {
  InvoiceTemplateNotifier() : super(_loadInitial());

  static InvoiceTemplate _loadInitial() {
    try {
      final savedId = DataPreferences.getInvoiceTemplate();
      return InvoiceTemplate.fromId(savedId);
    } catch (_) {
      return InvoiceTemplate.modernNavy;
    }
  }

  Future<void> setTemplate(InvoiceTemplate template) async {
    state = template;
    await DataPreferences.setInvoiceTemplate(template.id);
  }
}

final invoiceTemplateProvider =
    StateNotifierProvider<InvoiceTemplateNotifier, InvoiceTemplate>((ref) {
  return InvoiceTemplateNotifier();
});
