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
    final responseData = await ApiClient.get(ApiEndpoint.packages);
    final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((item) => DecorationPackage.fromJson(item as Map<String, dynamic>)).toList();
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
    double packagePrice = 0.0,
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
      if (packagePrice > 0) 'package_price': packagePrice,
      if (notes.isNotEmpty) 'notes': notes,
    };

    final responseData = await ApiClient.post(ApiEndpoint.agendas, body: payload);

    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengupdate nominal pembayaran DP untuk agenda tertentu
  Future<AgendaItem> updateAgendaDp(String agendaId, double dpAmount) async {
    final payload = {'dp_amount': dpAmount};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/dp', body: payload);
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengupdate nominal uang transport untuk agenda tertentu
  Future<AgendaItem> updateAgendaTransport(String agendaId, double transportFee) async {
    final payload = {'transport_fee': transportFee};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/transport', body: payload);
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengupdate paket dekorasi dan harga paket untuk agenda tertentu
  Future<AgendaItem> updateAgendaPackage(
    String agendaId, {
    required String packageId,
    required String packageName,
    required double packagePrice,
    String formToken = '',
    String eventAddress = '',
  }) async {
    final payload = {
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
    };

    try {
      final responseData = await ApiClient.put(
        '${ApiEndpoint.agendas}/$agendaId/package',
        body: payload,
      );
      return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      // Jika endpoint /package belum aktif di VPS (404),
      // gunakan fallback via endpoint client-form yang sudah aktif di live server
      if (e.statusCode == 404 && formToken.isNotEmpty) {
        final formPayload = {
          'package_id': packageId,
          'event_address': eventAddress.isNotEmpty ? eventAddress : '-',
          'addon_ids': <String>[],
        };
        await ApiClient.post('/client-form/$formToken', body: formPayload);

        final agendas = await getAgendas();
        return agendas.firstWhere((a) => a.id == agendaId);
      }
      rethrow;
    }
  }

  /// Mengupdate status pembayaran agenda (unpaid, dp, paid)
  Future<AgendaItem> updatePaymentStatus(String agendaId, String paymentStatus) async {
    final payload = {'payment_status': paymentStatus};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/payment-status', body: payload);
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengupdate status acara agenda (upcoming, completed, cancelled)
  Future<AgendaItem> updateEventStatus(String agendaId, String status) async {
    final payload = {'status': status};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/status', body: payload);
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }
}

