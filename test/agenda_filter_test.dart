import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/ui/features/agenda/view_models/agenda_view_model.dart';

void main() {
  group('AgendaFilterState and agendaFilterProvider', () {
    test('default filterType should be thisWeek', () {
      const defaultState = AgendaFilterState();
      expect(defaultState.filterType, equals(AgendaDateFilterType.thisWeek));
      expect(defaultState.customStartDate, isNull);
      expect(defaultState.customEndDate, isNull);
    });

    test('agendaFilterProvider should default to thisWeek', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(agendaFilterProvider);
      expect(state.filterType, equals(AgendaDateFilterType.thisWeek));
    });

    test('setFilter updates filterType and resetFilter restores thisWeek default', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Keep provider alive by listening
      container.listen(agendaViewModelProvider, (_, _) {});

      final viewModel = container.read(agendaViewModelProvider.notifier);

      // Change filter to all
      await viewModel.setFilter(AgendaDateFilterType.all);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(agendaFilterProvider).filterType, equals(AgendaDateFilterType.all));

      // Change filter to today
      await viewModel.setFilter(AgendaDateFilterType.today);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(agendaFilterProvider).filterType, equals(AgendaDateFilterType.today));

      // Reset filter
      await viewModel.resetFilter();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(agendaFilterProvider).filterType, equals(AgendaDateFilterType.thisWeek));
    });
  });
}
