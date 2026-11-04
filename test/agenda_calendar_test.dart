import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_calendar_view_model.dart';

class FakeAgendaService extends AgendaService {
  List<AgendaItem> fakeAgendas = [];

  @override
  Future<List<AgendaItem>> getAgendas({DateTime? startDate, DateTime? endDate}) async {
    return fakeAgendas;
  }
}

void main() {
  group('AgendaCalendarState & dateKey', () {
    test('dateKey formats yyyy-MM-dd properly', () {
      final date = DateTime(2026, 4, 9);
      expect(AgendaCalendarState.dateKey(date), equals('2026-04-09'));

      final date2 = DateTime(2026, 12, 25);
      expect(AgendaCalendarState.dateKey(date2), equals('2026-12-25'));
    });

    test('selectedDateAgendas returns agendas sorted by eventDateTime', () {
      final now = DateTime(2026, 4, 18);
      final key = AgendaCalendarState.dateKey(now);

      final itemLate = AgendaItem(
        id: '1',
        clientName: 'Client 1',
        backdropTitle: 'Title 1',
        eventDateTime: DateTime(2026, 4, 18, 14, 0),
        mapsUrl: '',
        packageId: '',
        packageName: 'Paket A',
      );

      final itemEarly = AgendaItem(
        id: '2',
        clientName: 'Client 2',
        backdropTitle: 'Title 2',
        eventDateTime: DateTime(2026, 4, 18, 9, 30),
        mapsUrl: '',
        packageId: '',
        packageName: 'Paket B',
      );

      final state = AgendaCalendarState(
        focusedMonth: DateTime(2026, 4, 1),
        selectedDate: now,
        agendasByDateKey: {
          key: [itemLate, itemEarly],
        },
      );

      final result = state.selectedDateAgendas;
      expect(result.length, equals(2));
      expect(result.first.id, equals('2')); // itemEarly first
      expect(result.last.id, equals('1')); // itemLate second
    });
  });

  group('AgendaCalendarNotifier', () {
    late FakeAgendaService fakeService;
    late ProviderContainer container;

    setUp(() {
      fakeService = FakeAgendaService();
      container = ProviderContainer(
        overrides: [
          agendaServiceProvider.overrideWithValue(fakeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with current month and today', () async {
      final now = DateTime.now();
      final state = container.read(agendaCalendarViewModelProvider);

      expect(state.focusedMonth.year, equals(now.year));
      expect(state.focusedMonth.month, equals(now.month));
      expect(state.focusedMonth.day, equals(1));

      expect(state.selectedDate.year, equals(now.year));
      expect(state.selectedDate.month, equals(now.month));
      expect(state.selectedDate.day, equals(now.day));
    });

    test('selectDate updates selectedDate immediately', () async {
      final notifier = container.read(agendaCalendarViewModelProvider.notifier);
      final targetDate = DateTime(2026, 4, 21);

      notifier.selectDate(targetDate);
      final state = container.read(agendaCalendarViewModelProvider);

      expect(state.selectedDate.year, equals(2026));
      expect(state.selectedDate.month, equals(4));
      expect(state.selectedDate.day, equals(21));
    });

    test('previousMonth and nextMonth shifts month correctly', () async {
      final notifier = container.read(agendaCalendarViewModelProvider.notifier);
      final currentMonth = container.read(agendaCalendarViewModelProvider).focusedMonth;

      notifier.nextMonth();
      var state = container.read(agendaCalendarViewModelProvider);
      final expectedNext = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      expect(state.focusedMonth.year, equals(expectedNext.year));
      expect(state.focusedMonth.month, equals(expectedNext.month));

      notifier.previousMonth();
      state = container.read(agendaCalendarViewModelProvider);
      expect(state.focusedMonth.year, equals(currentMonth.year));
      expect(state.focusedMonth.month, equals(currentMonth.month));
    });

    test('loads and groups agendas into agendasByDateKey', () async {
      final date1 = DateTime(2026, 4, 9, 10, 0);
      final date2 = DateTime(2026, 4, 18, 8, 0);
      final date3 = DateTime(2026, 4, 18, 15, 0);

      fakeService.fakeAgendas = [
        AgendaItem(
          id: 'agd_01',
          clientName: 'Alice',
          backdropTitle: 'Wedding Alice',
          eventDateTime: date1,
          mapsUrl: '',
          packageId: '',
          packageName: 'Gold',
        ),
        AgendaItem(
          id: 'agd_02',
          clientName: 'Bob',
          backdropTitle: 'Lamaran Bob',
          eventDateTime: date2,
          mapsUrl: '',
          packageId: '',
          packageName: 'Silver',
        ),
        AgendaItem(
          id: 'agd_03',
          clientName: 'Charlie',
          backdropTitle: 'Akad Charlie',
          eventDateTime: date3,
          mapsUrl: '',
          packageId: '',
          packageName: 'Platinum',
        ),
      ];

      final notifier = container.read(agendaCalendarViewModelProvider.notifier);
      await notifier.loadMonth(DateTime(2026, 4, 1));

      final state = container.read(agendaCalendarViewModelProvider);
      expect(state.agendasForDate(date1).length, equals(1));
      expect(state.agendasForDate(date2).length, equals(2));
      expect(state.agendasForDate(DateTime(2026, 4, 25)).length, equals(0));
    });
  });
}
