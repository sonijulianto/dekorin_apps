import 'package:flutter_test/flutter_test.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

void main() {
  group('DecorationModel', () {
    test('fromJson and toJson should work correctly', () {
      final json = {
        'id': 'mdl_01',
        'name': 'Model Rustic Arch Wood',
        'width': '3 Meter',
        'price': 1500000.0,
        'description': 'Backdrop arch kayu natural',
        'image_url': 'https://example.com/arch.jpg',
        'sort_order': 1,
      };

      final model = DecorationModel.fromJson(json);

      expect(model.id, 'mdl_01');
      expect(model.name, 'Model Rustic Arch Wood');
      expect(model.width, '3 Meter');
      expect(model.price, 1500000.0);
      expect(model.description, 'Backdrop arch kayu natural');
      expect(model.imageUrl, 'https://example.com/arch.jpg');
      expect(model.sortOrder, 1);

      final outputJson = model.toJson();
      expect(outputJson['id'], 'mdl_01');
      expect(outputJson['name'], 'Model Rustic Arch Wood');
      expect(outputJson['width'], '3 Meter');
      expect(outputJson['price'], 1500000.0);
    });

    test('copyWith should update fields correctly', () {
      const model = DecorationModel(
        id: 'mdl_01',
        name: 'Model Lama',
        width: '3 Meter',
        price: 1000000,
      );

      final updated = model.copyWith(
        name: 'Model Baru',
        width: '4 Meter',
        price: 1200000,
      );

      expect(updated.id, 'mdl_01');
      expect(updated.name, 'Model Baru');
      expect(updated.width, '4 Meter');
      expect(updated.price, 1200000);
    });
  });

  group('DecorationPackage with PackageModels', () {
    test('should parse packageModels and calculate surcharge correctly', () {
      final json = {
        'id': 'pkg_platinum',
        'name': 'Paket Platinum',
        'description': 'Paket dekorasi lengkap',
        'base_price': 5000000.0,
        'image_url': 'https://example.com/pkg.jpg',
        'sort_order': 1,
        'package_models': [
          {
            'id': 'pm_01',
            'package_id': 'pkg_platinum',
            'model_id': 'mdl_01',
            'additional_price': 0.0,
            'decoration_model': {
              'id': 'mdl_01',
              'name': 'Model Dekor A',
              'width': '3m',
              'price': 1500000.0,
            },
          },
          {
            'id': 'pm_02',
            'package_id': 'pkg_platinum',
            'model_id': 'mdl_02',
            'additional_price': 200000.0,
            'decoration_model': {
              'id': 'mdl_02',
              'name': 'Model Dekor B',
              'width': '4m',
              'price': 2500000.0,
            },
          },
        ],
      };

      final pkg = DecorationPackage.fromJson(json);

      expect(pkg.id, 'pkg_platinum');
      expect(pkg.name, 'Paket Platinum');
      expect(pkg.basePrice, 5000000.0);
      expect(pkg.packageModels.length, 2);

      final modelA = pkg.packageModels[0];
      expect(modelA.decorationModelId, 'mdl_01');
      expect(modelA.additionalPrice, 0.0);
      expect(modelA.decorationModel?.name, 'Model Dekor A');

      final modelB = pkg.packageModels[1];
      expect(modelB.decorationModelId, 'mdl_02');
      expect(modelB.additionalPrice, 200000.0);
      expect(modelB.decorationModel?.name, 'Model Dekor B');
    });
  });

  group('AgendaItem with Model Dekorasi', () {
    test('should parse and serialize model decoration attributes', () {
      final json = {
        'id': 'agd_001',
        'client_name': 'Sarah & Dimas',
        'client_phone': '08123456789',
        'backdrop_title': 'Wedding of Sarah & Dimas',
        'event_date_time': '2026-11-20T10:00:00.000Z',
        'maps_url': 'https://maps.google.com/?q=-6.2,106.8',
        'package_id': 'pkg_platinum',
        'package_name': 'Paket Platinum',
        'package_price': 5200000.0, // 5jt base + 200rb model B
        'model_id': 'mdl_02',
        'model_name': 'Model Dekor B',
        'model_width': '4 Meter',
        'model_image_url': 'https://example.com/model_b.jpg',
        'model_additional_price': 200000.0,
        'transport_fee': 300000.0,
        'status': 'upcoming',
        'payment_status': 'unpaid',
      };

      final agenda = AgendaItem.fromJson(json);

      expect(agenda.clientName, 'Sarah & Dimas');
      expect(agenda.packageName, 'Paket Platinum');
      expect(agenda.modelId, 'mdl_02');
      expect(agenda.modelName, 'Model Dekor B');
      expect(agenda.modelWidth, '4 Meter');
      expect(agenda.modelImageUrl, 'https://example.com/model_b.jpg');
      expect(agenda.modelAdditionalPrice, 200000.0);
      expect(agenda.packagePrice, 5200000.0);
      expect(agenda.calculatedTotalPrice, 5500000.0); // 5.2jt + 300rb transport
    });
  });
}
