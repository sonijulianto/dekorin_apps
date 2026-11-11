import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';
import 'package:dekorin_apps/data/models/ai_decor_simulation_model.dart';

final aiDecorServiceProvider = Provider<AiDecorService>((ref) {
  return AiDecorService();
});

final aiDecorHistoryProvider =
    StateNotifierProvider<AiDecorHistoryNotifier, List<AiDecorSimulationModel>>((ref) {
  return AiDecorHistoryNotifier();
});

class AiDecorService {
  /// Memproses simulasi kustomisasi warna dekorasi dengan Gemini Image Editing AI.
  /// Bisa menggunakan [image] dari Galeri/Kamera ataupun [imageUrl] dari katalog yang sudah ada.
  Future<AiDecorSimulationModel> simulateDecor({
    PickedImageData? image,
    String imageUrl = '',
    String modelName = '',
    String fabricColor = '',
    String flowerColor = '',
    String nuance = '',
    String notes = '',
  }) async {
    dynamic response;

    if (image != null) {
      response = await ApiClient.uploadMultipart(
        ApiEndpoint.aiSimulateDecor,
        fileField: 'image',
        image: image,
        fields: {
          'model_name': modelName.trim(),
          'fabric_color': fabricColor.trim(),
          'flower_color': flowerColor.trim(),
          'nuance': nuance.trim(),
          'notes': notes.trim(),
        },
        timeout: const Duration(seconds: 95),
      );
    } else {
      response = await ApiClient.post(
        ApiEndpoint.aiSimulateDecor,
        body: {
          'image_url': imageUrl.trim(),
          'model_name': modelName.trim(),
          'fabric_color': fabricColor.trim(),
          'flower_color': flowerColor.trim(),
          'nuance': nuance.trim(),
          'notes': notes.trim(),
        },
        timeout: const Duration(seconds: 95),
      );
    }

    final mapData = (response is Map<String, dynamic>)
        ? (response['data'] as Map<String, dynamic>? ?? <String, dynamic>{})
        : <String, dynamic>{};

    return AiDecorSimulationModel.fromJson(mapData);
  }
}

/// Menyimpan daftar simulasi terbaru di penyimpanan lokal HP (maksimal 25 item terakhir).
class AiDecorHistoryNotifier extends StateNotifier<List<AiDecorSimulationModel>> {
  AiDecorHistoryNotifier() : super(const []) {
    _load();
  }

  void _load() {
    try {
      final raw = DataPreferences.getAiDecorHistory();
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded
            .whereType<Map<String, dynamic>>()
            .map(AiDecorSimulationModel.fromJson)
            .toList();
      }
    } catch (_) {
      state = const [];
    }
  }

  Future<void> addSimulation(AiDecorSimulationModel item) async {
    final updated = [
      item,
      ...state.where((existing) => existing.id != item.id),
    ];
    state = updated.take(25).toList();
    await _persist();
  }

  Future<void> removeSimulation(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> clearAll() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
      await DataPreferences.setAiDecorHistory(jsonStr);
    } catch (_) {}
  }
}
