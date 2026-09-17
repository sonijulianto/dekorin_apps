import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

final agendaServiceProvider = Provider<AgendaService>((ref) {
  return AgendaService();
});

/// Service yang menangani data agenda dan paket dekorasi dari backend.
///
/// Menggunakan [ApiClient] terpusat (tidak ada boilerplate HTTP).
class AgendaService {
  /// Mengambil daftar master paket dekorasi
  Future<List<DecorationPackage>> getPackages() async {
    try {
      final responseData = await ApiClient.get(ApiEndpoint.packages);
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data.map((item) => DecorationPackage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
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
  Future<List<AgendaItem>> getAgendas({DateTime? startDate, DateTime? endDate}) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final queryParams = <String>[];
    if (startDate != null) {
      queryParams.add('start_date=${formatter.format(startDate)}');
    }
    if (endDate != null) {
      queryParams.add('end_date=${formatter.format(endDate)}');
    }

    final queryPath = queryParams.isNotEmpty ? '${ApiEndpoint.agendas}?${queryParams.join('&')}' : ApiEndpoint.agendas;

    try {
      final responseData = await ApiClient.get(queryPath);
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data.map((item) => AgendaItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
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
          if (startDate != null && agenda.eventDateTime.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
            return false;
          }
          if (endDate != null && agenda.eventDateTime.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59))) {
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
    String clientPhone = '',
    String backdropTitle = '',
    DateTime? eventDateTime,
    String mapsUrl = '',
    String packageId = '',
    String notes = '',
  }) async {
    final formattedDate = eventDateTime != null
        ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime)
        : '';

    final payload = {
      'client_name': clientName,
      'client_phone': clientPhone,
      if (backdropTitle.isNotEmpty) 'backdrop_title': backdropTitle,
      if (formattedDate.isNotEmpty) 'event_date_time': formattedDate,
      if (mapsUrl.isNotEmpty) 'maps_url': mapsUrl,
      if (packageId.isNotEmpty) 'package_id': packageId,
      if (notes.isNotEmpty) 'notes': notes,
    };

    final responseData = await ApiClient.post(ApiEndpoint.agendas, body: payload);

    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }
}
