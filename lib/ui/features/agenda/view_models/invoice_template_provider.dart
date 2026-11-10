import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class InvoiceTemplateState {
  final InvoiceTemplate defaultTemplate;
  final Map<String, InvoiceTemplate> brandTemplates;
  final Set<String> inheritedBrandIds;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const InvoiceTemplateState({
    this.defaultTemplate = InvoiceTemplate.modernNavy,
    this.brandTemplates = const {'': InvoiceTemplate.modernNavy},
    this.inheritedBrandIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  /// Mengambil template aktif untuk Brand tertentu (atau fallback ke Brand Utama jika belum disetel khusus).
  InvoiceTemplate templateForBrand(String brandId) {
    final key = brandId.trim();
    if (key.isNotEmpty && brandTemplates.containsKey(key)) {
      return brandTemplates[key]!;
    }
    return brandTemplates[''] ?? defaultTemplate;
  }

  /// Mengetahui apakah Sub-Brand masih mewarisi template Brand Utama.
  bool isBrandInherited(String brandId) {
    final key = brandId.trim();
    if (key.isEmpty) return false;
    return inheritedBrandIds.contains(key);
  }

  InvoiceTemplateState copyWith({
    InvoiceTemplate? defaultTemplate,
    Map<String, InvoiceTemplate>? brandTemplates,
    Set<String>? inheritedBrandIds,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InvoiceTemplateState(
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      brandTemplates: brandTemplates ?? this.brandTemplates,
      inheritedBrandIds: inheritedBrandIds ?? this.inheritedBrandIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InvoiceTemplateNotifier extends StateNotifier<InvoiceTemplateState> {
  InvoiceTemplateNotifier(this._ref, {InvoiceTemplate initialDefault = InvoiceTemplate.modernNavy})
      : super(
          InvoiceTemplateState(
            defaultTemplate: initialDefault,
            brandTemplates: {'': initialDefault},
          ),
        );

  final Ref _ref;

  /// Sinkronisasi konfigurasi template invoice Brand Utama & seluruh Sub-Brand dari database.
  Future<bool> syncFromServer({String brandId = ''}) async {
    final user = _ref.read(globalAuthProvider).valueOrNull;
    if (user == null) return false;

    if (mounted) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final config = await _ref.read(companyServiceProvider).getInvoiceTemplate(brandId: brandId);
      if (!mounted) return false;

      state = state.copyWith(
        defaultTemplate: config.companyInvoiceTemplate,
        brandTemplates: config.brandTemplates,
        inheritedBrandIds: config.inheritedBrandIds,
        isLoading: false,
        clearError: true,
      );

      await _ref
          .read(globalAuthProvider.notifier)
          .updateCompanyInvoiceTemplate(config.companyInvoiceTemplate.id);
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return false;
    }
  }

  /// Menyimpan template invoice untuk Brand Utama (brandId = '') atau Sub-Brand ke database.
  Future<void> setTemplateForBrand({
    String brandId = '',
    required InvoiceTemplate template,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final config = await _ref.read(companyServiceProvider).updateInvoiceTemplate(
            brandId: brandId,
            templateId: template.id,
          );
      if (!mounted) return;

      final updatedMap = Map<String, InvoiceTemplate>.from(config.brandTemplates);
      updatedMap[brandId.trim()] = config.invoiceTemplate;

      final updatedInherited = Set<String>.from(config.inheritedBrandIds);
      if (brandId.trim().isNotEmpty) {
        updatedInherited.remove(brandId.trim());
      }

      state = state.copyWith(
        defaultTemplate: config.companyInvoiceTemplate,
        brandTemplates: updatedMap,
        inheritedBrandIds: updatedInherited,
        isSaving: false,
        clearError: true,
      );

      await _ref
          .read(globalAuthProvider.notifier)
          .updateCompanyInvoiceTemplate(config.companyInvoiceTemplate.id);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      rethrow;
    }
  }
}

final invoiceTemplateProvider =
    StateNotifierProvider<InvoiceTemplateNotifier, InvoiceTemplateState>((ref) {
  // Rebuild state notifier secara bersih saat akun/perusahaan berganti (login/logout)
  final authSessionKey = ref.watch(
    globalAuthProvider.select((asyncUser) {
      final u = asyncUser.valueOrNull;
      return u == null ? null : '${u.id}::${u.companyId}';
    }),
  );

  final user = ref.read(globalAuthProvider).valueOrNull;
  final initialDefault = InvoiceTemplate.fromId(user?.companyInvoiceTemplate);
  final notifier = InvoiceTemplateNotifier(ref, initialDefault: initialDefault);

  if (authSessionKey != null) {
    Future.microtask(() => notifier.syncFromServer());
  }

  return notifier;
});
