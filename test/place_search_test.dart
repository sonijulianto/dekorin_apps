import 'package:flutter_test/flutter_test.dart';
import 'package:dekorin_apps/data/services/place_search_service.dart';

void main() {
  group('PlaceSearchResult Model Tests', () {
    test('fullAddress correctly combines name and address', () {
      const place = PlaceSearchResult(
        name: 'Hotel Santika Premiere',
        address: 'Jl. Harapan Indah Bulevar, Bekasi',
        latitude: -6.1848,
        longitude: 106.9758,
        mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-6.1848,106.9758',
      );

      expect(place.fullAddress, 'Hotel Santika Premiere, Jl. Harapan Indah Bulevar, Bekasi');
      expect(place.mapsUrl, contains('-6.1848,106.9758'));
    });

    test('fullAddress does not duplicate name if address already starts with name', () {
      const place = PlaceSearchResult(
        name: 'Hotel Santika',
        address: 'Hotel Santika, Botani Square, Bogor',
        latitude: -6.6011,
        longitude: 106.8067,
        mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-6.6011,106.8067',
      );

      expect(place.fullAddress, 'Hotel Santika, Botani Square, Bogor');
    });

    test('fullAddress returns name when address is empty', () {
      const place = PlaceSearchResult(
        name: 'Gedung Pernikahan Harmoni',
        address: '',
        latitude: 0,
        longitude: 0,
        mapsUrl: '',
      );

      expect(place.fullAddress, 'Gedung Pernikahan Harmoni');
    });

    test('searchPlaces returns empty list for short queries', () async {
      final results = await PlaceSearchService.searchPlaces('a');
      expect(results, isEmpty);
    });
  });
}
