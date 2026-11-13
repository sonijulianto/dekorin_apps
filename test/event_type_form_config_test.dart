import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';

void main() {
  group('FormTemplateSummary & AgendaItem eventType', () {
    test('resolveLabel maps built-in and custom event types safely', () {
      expect(FormTemplateSummary.resolveLabel(''), 'Umum (Default)');
      expect(FormTemplateSummary.resolveLabel('wedding'), 'Wedding');
      expect(FormTemplateSummary.resolveLabel('lamaran'), 'Lamaran');
      expect(FormTemplateSummary.resolveLabel('birthday'), 'Ulang Tahun');
      expect(FormTemplateSummary.resolveLabel('aqiqah'), 'Aqiqah');
      expect(FormTemplateSummary.resolveLabel('custom_khitanan_anak'), 'Khitanan Anak');
      expect(
        FormTemplateSummary.resolveLabel('custom_corp', 'Corporate Event'),
        'Corporate Event',
      );
    });

    test('AgendaItem fromJson handles missing event_type backward-compatibly', () {
      final legacy = AgendaItem.fromJson({
        'id': 'agd_legacy',
        'client_name': 'Rian & Nisa',
        'backdrop_title': 'The Engagement',
        'event_date_time': '2026-12-20T10:00:00',
        'maps_url': '',
        'package_id': '',
        'package_name': '',
      });
      expect(legacy.eventType, '');
      expect(legacy.eventLabel, '');
      expect(legacy.displayEventLabel, '');

      final birthday = AgendaItem.fromJson({
        'id': 'agd_bday',
        'client_name': 'Ibu Rina',
        'backdrop_title': 'Happy 5th Birthday Kenzo',
        'event_date_time': '2026-12-21T15:00:00',
        'maps_url': '',
        'package_id': '',
        'package_name': '',
        'event_type': 'birthday',
        'event_label': 'Ulang Tahun',
      });
      expect(birthday.eventType, 'birthday');
      expect(birthday.displayEventLabel, 'Ulang Tahun');
    });

    test('CompanyFormConfig parses event_type and event_label safely', () {
      final cfg = CompanyFormConfig.fromJson({
        'id': 'fcfg_1',
        'company_id': 'cmp_1',
        'brand_id': '',
        'event_type': 'lamaran',
        'event_label': 'Lamaran',
        'show_price': true,
        'fields': [],
      });
      expect(cfg.eventType, 'lamaran');
      expect(cfg.eventLabel, 'Lamaran');
    });
  });
}
