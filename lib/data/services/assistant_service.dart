import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';

/// Struktur data balasan dari Asisten Dekorin AI
class AssistantReply {
  final String text;
  final List<String> suggestions;

  const AssistantReply({
    required this.text,
    this.suggestions = const [],
  });
}

final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService();
});

/// Service untuk berkomunikasi dengan endpoint Asisten Cerdas Dekorin di backend
class AssistantService {
  Future<AssistantReply> askAssistant({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final response = await ApiClient.post(
      ApiEndpoint.aiAssistant,
      body: {
        'message': message,
        'history': history,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final reply = data['reply'] as String? ?? 'Maaf, belum ada data yang bisa ditampilkan saat ini.';
    final suggestions = (data['suggestions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AssistantReply(text: reply, suggestions: suggestions);
  }
}
