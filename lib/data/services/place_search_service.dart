import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model hasil pencarian lokasi / tempat (venue, gedung, hotel, dll.)
class PlaceSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String mapsUrl;

  const PlaceSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.mapsUrl,
  });

  /// Menggabungkan nama tempat dan alamat detail
  String get fullAddress {
    if (address.isEmpty) return name;
    if (name.isEmpty) return address;
    if (address.toLowerCase().startsWith(name.toLowerCase())) {
      return address;
    }
    return '$name, $address';
  }
}

/// Service untuk mencari rekomendasi tempat / alamat secara otomatis
/// tanpa memerlukan API key Google Places berbayar (menggunakan Photon OSM & Nominatim fallback).
class PlaceSearchService {
  static final http.Client _client = http.Client();

  /// Mencari lokasi tempat / venue berdasarkan query teks
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    // 1. Coba gunakan Photon API (cepat, autocomplete, typo-tolerant)
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=8&lang=id',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final results = <PlaceSearchResult>[];
          for (var item in features) {
            final props = item['properties'] as Map<String, dynamic>? ?? {};
            final geom = item['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List<dynamic>? ?? [0.0, 0.0];

            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final name = (props['name'] as String?)?.trim() ?? '';

            final parts = <String>[];
            final street = (props['street'] as String?)?.trim();
            final district = (props['district'] as String?)?.trim();
            final city = (props['city'] as String?)?.trim();
            final state = (props['state'] as String?)?.trim();

            if (street != null && street.isNotEmpty && street != name) parts.add(street);
            if (district != null && district.isNotEmpty) parts.add(district);
            if (city != null && city.isNotEmpty) parts.add(city);
            if (state != null && state.isNotEmpty) parts.add(state);

            final address = parts.join(', ');
            final displayName = name.isNotEmpty ? name : (street ?? 'Lokasi Acara');
            final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';

            results.add(PlaceSearchResult(
              name: displayName,
              address: address,
              latitude: lat,
              longitude: lon,
              mapsUrl: mapsUrl,
            ));
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {}

    // 2. Fallback ke OpenStreetMap Nominatim API
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=8&countrycodes=id',
      );
      final res = await _client.get(
        uri,
        headers: {'User-Agent': 'DekorinApp/1.0 (contact@dekorin.id)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>? ?? [];
        final results = <PlaceSearchResult>[];
        for (var item in list) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(map['lon']?.toString() ?? '') ?? 0.0;
          final name = (map['name'] as String?)?.trim() ?? '';
          final displayName = (map['display_name'] as String?)?.trim() ?? '';

          String address = displayName;
          if (name.isNotEmpty && address.startsWith(name)) {
            address = address.substring(name.length).trim();
            if (address.startsWith(',')) {
              address = address.substring(1).trim();
            }
          }

          final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
          results.add(PlaceSearchResult(
            name: name.isNotEmpty ? name : displayName,
            address: address,
            latitude: lat,
            longitude: lon,
            mapsUrl: mapsUrl,
          ));
        }
        return results;
      }
    } catch (_) {}

    return [];
  }
}
