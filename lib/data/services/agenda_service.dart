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
    String brandId = '',
    required String clientName,
    String clientPhone = '',
    String backdropTitle = '',
    DateTime? eventDateTime,
    String eventAddress = '',
    String mapsUrl = '',
    String packageId = '',
    double packagePrice = 0.0,
    String modelId = '',
    String modelName = '',
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String discountType = 'amount',
    double discountValue = 0.0,
    double transportFee = 0.0,
    double dpAmount = 0.0,
    String paymentStatus = '',
    String notes = '',
  }) async {
    final formattedDate = eventDateTime != null
        ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime)
        : '';

    final payload = {
      'brand_id': brandId,
      'client_name': clientName,
      'client_phone': clientPhone,
      if (backdropTitle.isNotEmpty) 'backdrop_title': backdropTitle,
      if (formattedDate.isNotEmpty) 'event_date_time': formattedDate,
      if (eventAddress.isNotEmpty) 'event_address': eventAddress,
      if (mapsUrl.isNotEmpty) 'maps_url': mapsUrl,
      if (packageId.isNotEmpty) 'package_id': packageId,
      if (packagePrice > 0) 'package_price': packagePrice,
      if (modelId.isNotEmpty) 'model_id': modelId,
      if (modelName.isNotEmpty) 'model_name': modelName,
      if (modelWidth.isNotEmpty) 'model_width': modelWidth,
      if (modelImageUrl.isNotEmpty) 'model_image_url': modelImageUrl,
      if (modelAdditionalPrice > 0) 'model_additional_price': modelAdditionalPrice,
      if (discountValue > 0) 'discount_type': AgendaItem.normalizeDiscountType(discountType),
      if (discountValue > 0) 'discount_value': discountValue,
      if (transportFee > 0) 'transport_fee': transportFee,
      if (dpAmount > 0) 'dp_amount': dpAmount,
      if (paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
      if (notes.isNotEmpty) 'notes': notes,
    };

    final responseData = await ApiClient.post(ApiEndpoint.agendas, body: payload);

    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengupdate Brand / Sub-Brand untuk agenda tertentu
  Future<AgendaItem> updateAgendaBrand(String agendaId, String brandId) async {
    final payload = {'brand_id': brandId};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/brand', body: payload);
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
    String modelId = '',
    String modelName = '',
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String formToken = '',
    String eventAddress = '',
  }) async {
    final payload = {
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
      if (modelId.isNotEmpty) 'model_id': modelId,
      if (modelName.isNotEmpty) 'model_name': modelName,
      if (modelWidth.isNotEmpty) 'model_width': modelWidth,
      if (modelImageUrl.isNotEmpty) 'model_image_url': modelImageUrl,
      if (modelAdditionalPrice > 0) 'model_additional_price': modelAdditionalPrice,
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

  /// Mengupdate model dekorasi untuk agenda tertentu
  Future<AgendaItem> updateAgendaModel(
    String agendaId, {
    required String modelId,
    required String modelName,
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String packageId = '',
    String packageName = '',
    double packagePrice = 0.0,
    String formToken = '',
    String eventAddress = '',
  }) async {
    final payload = {
      'model_id': modelId,
      'model_name': modelName,
      'model_width': modelWidth,
      'model_image_url': modelImageUrl,
      'model_additional_price': modelAdditionalPrice,
    };

    try {
      final responseData = await ApiClient.put(
        '${ApiEndpoint.agendas}/$agendaId/model',
        body: payload,
      );
      return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      final is404 = e.statusCode == 404 || e.message.contains('Cannot PUT') || e.message.contains('404');
      if (is404 && packageId.isNotEmpty) {
        // Jika endpoint /model belum aktif di server (404), gunakan fallback ke /package
        return updateAgendaPackage(
          agendaId,
          packageId: packageId,
          packageName: packageName,
          packagePrice: packagePrice,
          modelId: modelId,
          modelName: modelName,
          modelWidth: modelWidth,
          modelImageUrl: modelImageUrl,
          modelAdditionalPrice: modelAdditionalPrice,
          formToken: formToken,
          eventAddress: eventAddress,
        );
      }
      if (is404) {
        throw ApiException(
          'Fitur simpan model dekorasi memerlukan pembaruan server. Silakan jalankan ./update.sh pada server VPS.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  /// Mengupdate catatan atau request tambahan untuk agenda tertentu
  Future<AgendaItem> updateAgendaNotes(
    String agendaId,
    String notes, {
    String formToken = '',
  }) async {
    final payload = {'notes': notes};
    try {
      final responseData = await ApiClient.put(
        '${ApiEndpoint.agendas}/$agendaId/notes',
        body: payload,
      );
      return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      final is404 = e.statusCode == 404 || e.message.contains('Cannot PUT') || e.message.contains('404');
      if (is404) {
        throw ApiException(
          'Fitur simpan catatan memerlukan pembaruan server. Silakan jalankan ./update.sh pada server VPS.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  /// Mengupdate status pembayaran agenda (unpaid, dp, paid)
  Future<AgendaItem> updatePaymentStatus(
    String agendaId,
    String paymentStatus, {
    DateTime? fallbackEventDateTime,
  }) async {
    final payload = {'payment_status': paymentStatus};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/payment-status', body: payload);
    return AgendaItem.fromJson(
      responseData['data'] as Map<String, dynamic>,
      fallbackEventDateTime: fallbackEventDateTime,
    );
  }

  /// Mengupdate status acara agenda (upcoming, completed, cancelled)
  Future<AgendaItem> updateEventStatus(
    String agendaId,
    String status, {
    DateTime? fallbackEventDateTime,
  }) async {
    final payload = {'status': status};
    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/status', body: payload);
    return AgendaItem.fromJson(
      responseData['data'] as Map<String, dynamic>,
      fallbackEventDateTime: fallbackEventDateTime,
    );
  }

  /// Mengupdate jadwal acara (tanggal dan jam) untuk agenda aktif
  Future<AgendaItem> updateAgendaSchedule(String agendaId, DateTime eventDateTime) async {
    final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime);
    final payload = {'event_date_time': formattedDate};
    try {
      final responseData = await ApiClient.put(
        '${ApiEndpoint.agendas}/$agendaId/schedule',
        body: payload,
      );
      return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      final is404 = e.statusCode == 404 || e.message.contains('Cannot PUT') || e.message.contains('404');
      if (is404) {
        // Fallback ke endpoint utama /agendas/:id jika route /schedule belum aktif di live server
        final responseData = await ApiClient.put(
          '${ApiEndpoint.agendas}/$agendaId',
          body: payload,
        );
        return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  /// Mengupdate alamat dan lokasi Maps acara untuk agenda aktif
  Future<AgendaItem> updateAgendaLocation(
    String agendaId, {
    required String eventAddress,
    String mapsUrl = '',
  }) async {
    final payload = {
      'event_address': eventAddress,
      'maps_url': mapsUrl,
    };
    try {
      final responseData = await ApiClient.put(
        '${ApiEndpoint.agendas}/$agendaId/location',
        body: payload,
      );
      return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      final is404 = e.statusCode == 404 || e.message.contains('Cannot PUT') || e.message.contains('404');
      if (is404) {
        // Fallback ke endpoint utama /agendas/:id jika route /location belum aktif di live server
        final responseData = await ApiClient.put(
          '${ApiEndpoint.agendas}/$agendaId',
          body: payload,
        );
        return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  /// Mengupdate seluruh data agenda secara lengkap (PUT /api/agendas/:id)
  Future<AgendaItem> updateAgenda(
    String agendaId, {
    String brandId = '',
    required String clientName,
    String clientPhone = '',
    String backdropTitle = '',
    DateTime? eventDateTime,
    String eventAddress = '',
    String mapsUrl = '',
    String packageId = '',
    String packageName = '',
    double packagePrice = 0.0,
    String modelId = '',
    String modelName = '',
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String discountType = 'amount',
    double discountValue = 0.0,
    double transportFee = 0.0,
    double dpAmount = 0.0,
    String paymentStatus = '',
    String status = '',
    String notes = '',
  }) async {
    final formattedDate = eventDateTime != null
        ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime)
        : '';

    final payload = {
      'brand_id': brandId,
      'client_name': clientName,
      'client_phone': clientPhone,
      'backdrop_title': backdropTitle,
      if (formattedDate.isNotEmpty) 'event_date_time': formattedDate,
      'event_address': eventAddress,
      'maps_url': mapsUrl,
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
      'model_id': modelId,
      'model_name': modelName,
      'model_width': modelWidth,
      'model_image_url': modelImageUrl,
      'model_additional_price': modelAdditionalPrice,
      'discount_type': AgendaItem.normalizeDiscountType(discountType),
      'discount_value': discountValue,
      'transport_fee': transportFee,
      'dp_amount': dpAmount,
      if (paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
      if (status.isNotEmpty) 'status': status,
      'notes': notes,
    };

    final responseData = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId', body: payload);
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Membuat link form kosong untuk diisi client (tidak masuk agenda utama sebelum client mengisi)
  Future<AgendaItem> generateClientFormLink({
    String brandId = '',
    String label = '',
  }) async {
    final responseData = await ApiClient.post(
      ApiEndpoint.generateAgendaLink,
      body: {
        'brand_id': brandId,
        if (label.trim().isNotEmpty) 'label': label.trim(),
      },
    );
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Mengambil daftar link form client yang masih menunggu isian (is_form_draft = true)
  Future<List<AgendaItem>> getPendingClientLinks({String brandId = ''}) async {
    final query = brandId.isNotEmpty ? '?brand_id=${Uri.encodeComponent(brandId)}' : '';
    final responseData = await ApiClient.get('${ApiEndpoint.pendingAgendaLinks}$query');
    final List<dynamic> list = responseData['data'] as List<dynamic>? ?? [];
    return list.map((json) => AgendaItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Membuka kembali kunci form client agar client bisa mengisi ulang lewat link
  Future<AgendaItem> unlockAgendaForm(String agendaId) async {
    final responseData = await ApiClient.post('${ApiEndpoint.agendas}/$agendaId/unlock-form');
    return AgendaItem.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  /// Menghapus agenda atau draft link form client
  Future<void> deleteAgenda(String agendaId) async {
    await ApiClient.delete('${ApiEndpoint.agendas}/$agendaId');
  }
}


