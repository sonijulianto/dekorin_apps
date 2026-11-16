import 'package:flutter_test/flutter_test.dart';
import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/ui/features/agenda/utils/agenda_category_config.dart';

void main() {
  group('AgendaCategoryConfig', () {
    test('decoration enables backdrop, model, concept card, and pick list', () {
      final cfg = AgendaCategoryConfig.fromCategory('decoration');
      expect(cfg.category, 'decoration');
      expect(cfg.isDecoration, isTrue);
      expect(cfg.showBackdropField, isTrue);
      expect(cfg.showModelSection, isTrue);
      expect(cfg.showModelConceptCard, isTrue);
      expect(cfg.showPickListAndCrewBrief, isTrue);
      expect(cfg.packageFieldLabel, 'Pilih Paket Dekorasi (Opsional)');
    });

    test('mua, photo_video, and mc hide decor-only sections and adapt labels', () {
      for (final raw in ['mua', 'photo_video', 'mc']) {
        final cfg = AgendaCategoryConfig.fromCategory(raw);
        expect(cfg.isDecoration, isFalse, reason: '$raw should not be decoration');
        expect(cfg.showBackdropField, isFalse);
        expect(cfg.showModelSection, isFalse);
        expect(cfg.showModelConceptCard, isFalse);
        expect(cfg.showPickListAndCrewBrief, isFalse);
        expect(cfg.packageSectionTitle, 'Paket Layanan');
      }

      expect(AgendaCategoryConfig.fromCategory('mua').packageFieldLabel, contains('MUA'));
      expect(AgendaCategoryConfig.fromCategory('photo_video').packageFieldLabel, contains('Foto & Video'));
      expect(AgendaCategoryConfig.fromCategory('mc').packageFieldLabel, contains('MC'));
    });

    test('UserModel parses company_category with decoration fallback', () {
      final muaUser = UserModel.fromJson({
        'id': 'u1',
        'full_name': 'Rina MUA',
        'company_category': 'mua',
      });
      expect(muaUser.companyCategory, 'mua');
      expect(muaUser.toDomain().companyCategory, 'mua');

      final defaultUser = UserModel.fromJson({
        'id': 'u2',
        'full_name': 'Soni Decor',
      });
      expect(defaultUser.companyCategory, 'decoration');
      expect(defaultUser.toDomain().companyCategory, 'decoration');
    });
  });
}
