import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

final agendaServiceProvider = Provider<AgendaService>((ref) {
  return AgendaService();
});

class AgendaService {
  // Gunakan 10.0.2.2 untuk Android emulator, 127.0.0.1 untuk iOS / Desktop / Web
  String get baseUrl {
    if (kIsWeb) return 'http://10.166.190.239:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.166.190.239:3000/api';
    }
    return 'http://10.166.190.239:3000/api';
  }

  /// Mengambil daftar master paket dekorasi
  Future<List<DecorationPackage>> getPackages() async {
    final url = Uri.parse('$baseUrl/packages');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
        return data
            .map((item) =>
                DecorationPackage.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Gagal memuat master paket: status ${response.statusCode}');
      }
    } catch (e) {
      // Fallback data jika backend belum tersambung
      return const [
        DecorationPackage(
          id: 'pkg_01',
          name: 'Paket Akad Minimalis',
          description: 'Backdrop 2.5m, rangkaian bunga artificial, karpet akad',
          basePrice: 2500000,
        ),
        DecorationPackage(
          id: 'pkg_02',
          name: 'Paket Lamaran Rustic / Modern',
          description: 'Backdrop 3m hexagon/arch, full bunga kombinasi, spotlight, welcome sign',
          basePrice: 4000000,
        ),
        DecorationPackage(
          id: 'pkg_03',
          name: 'Paket Pernikahan Elegan Gold',
          description: 'Pelaminan 6m, pergola, lighting lengkap, karpet jalan',
          basePrice: 9500000,
        ),
        DecorationPackage(
          id: 'pkg_04',
          name: 'Paket Grand Luxury Ballroom',
          description: 'Pelaminan 10-12m full fresh flower, chandelier, photobooth thematic',
          basePrice: 18000000,
        ),
      ];
    }
  }

  /// Mengambil daftar agenda mendatang dengan opsional filter tanggal
  Future<List<AgendaItem>> getAgendas({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = formatter.format(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = formatter.format(endDate);
    }

    final uri = Uri.parse('$baseUrl/agendas').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
        return data
            .map((item) => AgendaItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Gagal memuat agenda: status ${response.statusCode}');
      }
    } catch (e) {
      // Jika jaringan gagal, berikan fallback contoh
      final now = DateTime.now();
      final mock = [
        AgendaItem(
          id: 'agd_001',
          clientName: 'Rian & Nisa',
          backdropTitle: 'The Engagement of Rian & Nisa',
          eventDateTime: now.add(const Duration(days: 1, hours: 2)),
          mapsUrl: 'https://maps.google.com/?q=-6.2088,106.8456',
          packageId: 'pkg_02',
          packageName: 'Paket Lamaran Rustic / Modern',
          status: 'upcoming',
          notes: 'Tema warna Sage Green & Cream.',
        ),
        AgendaItem(
          id: 'agd_002',
          clientName: 'Dimas & Sarah',
          backdropTitle: 'Wedding Reception Dimas & Sarah',
          eventDateTime: now.add(const Duration(days: 3, hours: 4)),
          mapsUrl: 'https://maps.google.com/?q=-6.9175,107.6191',
          packageId: 'pkg_03',
          packageName: 'Paket Pernikahan Elegan Gold',
          status: 'upcoming',
          notes: 'Gedung Puri Ardhya Garini.',
        ),
      ];

      if (startDate != null || endDate != null) {
        return mock.where((agenda) {
          if (startDate != null &&
              agenda.eventDateTime.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
            return false;
          }
          if (endDate != null &&
              agenda.eventDateTime.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59))) {
            return false;
          }
          return true;
        }).toList();
      }
      return mock;
    }
  }

  /// Membuat agenda baru ke backend
  Future<AgendaItem> createAgenda({
    required String clientName,
    required String backdropTitle,
    required DateTime eventDateTime,
    required String mapsUrl,
    required String packageId,
    String notes = '',
  }) async {
    final url = Uri.parse('$baseUrl/agendas');
    final formattedDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime);

    final payload = {
      'client_name': clientName,
      'backdrop_title': backdropTitle,
      'event_date_time': formattedDate,
      'maps_url': mapsUrl,
      'package_id': packageId,
      'notes': notes,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return AgendaItem.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Gagal membuat agenda');
    }
  }
}
