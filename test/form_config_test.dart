import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';

void main() {
  group('FormConfig & Agenda Draft Parsing Tests', () {
    test('CompanyFormConfig.fromJson parses fields, options, and showPrice defensively', () {
      final json = {
        'id': 'fcfg_123',
        'company_id': 'cmp_1',
        'brand_id': 'brd_rustic',
        'show_price': false,
        'fields': [
          {
            'key': 'client_name',
            'label': 'Nama Pengantin',
            'type': 'text',
            'is_system': true,
            'is_active': true,
            'is_required': true,
            'sort_order': 1,
          },
          {
            'key': 'custom_lokasi',
            'label': 'Tipe Venue',
            'type': 'select',
            'options': ['Indoor', 'Outdoor'],
            'is_system': false,
            'is_active': true,
            'is_required': false,
            'sort_order': 2,
          },
        ],
      };

      final cfg = CompanyFormConfig.fromJson(json, isInherited: true);
      expect(cfg.id, 'fcfg_123');
      expect(cfg.brandId, 'brd_rustic');
      expect(cfg.showPrice, false);
      expect(cfg.isInherited, true);
      expect(cfg.fields.length, 2);
      expect(cfg.fields[0].isRequired, true);
      expect(cfg.fields[1].options, ['Indoor', 'Outdoor']);
      expect(cfg.fields[1].typeDisplayLabel, 'Dropdown');
    });

    test('AgendaItem.fromJson parses is_form_draft and client_form custom_answers safely', () {
      final json = {
        'id': 'agd_1',
        'client_name': 'Menunggu Isian Client',
        'form_token': 'dkr-1234',
        'form_status': 'pending',
        'is_form_draft': true,
        'client_form': {
          'id': 'frm_1',
          'agenda_id': 'agd_1',
          'event_address': 'Gedung A',
          'custom_answers': [
            {
              'key': 'custom_jam_loading',
              'label': 'Jam Loading',
              'type': 'text',
              'value': '22:00 WIB',
            },
          ],
        },
      };

      final agenda = AgendaItem.fromJson(json);
      expect(agenda.isFormDraft, true);
      expect(agenda.formStatus, 'pending');
      expect(agenda.clientForm, isNotNull);
      expect(agenda.clientForm!.customAnswers.length, 1);
      expect(agenda.clientForm!.customAnswers.first.label, 'Jam Loading');
      expect(agenda.clientForm!.customAnswers.first.value, '22:00 WIB');
    });
  });
}
