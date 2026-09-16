import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

enum AgendaDateFilterType {
  all,
  today,
  thisWeek,
  thisMonth,
  customRange,
}

class AgendaFilterState {
  const AgendaFilterState({
    this.filterType = AgendaDateFilterType.all,
    this.customStartDate,
    this.customEndDate,
  });

  final AgendaDateFilterType filterType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  AgendaFilterState copyWith({
    AgendaDateFilterType? filterType,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return AgendaFilterState(
      filterType: filterType ?? this.filterType,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

final agendaFilterProvider =
    StateProvider<AgendaFilterState>((ref) => const AgendaFilterState());

final packagesProvider = FutureProvider<List<DecorationPackage>>((ref) async {
  final service = ref.watch(agendaServiceProvider);
  return service.getPackages();
});

typedef AgendaStateData = ({
  List<AgendaItem> agendas,
  AgendaFilterState filter,
});

final agendaViewModelProvider =
    AutoDisposeAsyncNotifierProvider<AgendaViewModel, AgendaStateData>(() {
  return AgendaViewModel();
});

class AgendaViewModel extends AutoDisposeAsyncNotifier<AgendaStateData> {
  @override
  Future<AgendaStateData> build() async {
    final filter = ref.watch(agendaFilterProvider);
    return _fetchAgendas(filter);
  }

  Future<AgendaStateData> _fetchAgendas(AgendaFilterState filter) async {
    final service = ref.read(agendaServiceProvider);

    DateTime? start;
    DateTime? end;
    final now = DateTime.now();

    switch (filter.filterType) {
      case AgendaDateFilterType.all:
        start = null;
        end = null;
        break;
      case AgendaDateFilterType.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day);
        break;
      case AgendaDateFilterType.thisWeek:
        // Mulai dari hari ini hingga akhir minggu (misal 7 hari ke depan)
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 7));
        break;
      case AgendaDateFilterType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        final nextMonth = (now.month == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        end = nextMonth.subtract(const Duration(days: 1));
        break;
      case AgendaDateFilterType.customRange:
        start = filter.customStartDate;
        end = filter.customEndDate;
        break;
    }

    final agendas = await service.getAgendas(startDate: start, endDate: end);
    return (
      agendas: agendas,
      filter: filter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final filter = ref.read(agendaFilterProvider);
      final data = await _fetchAgendas(filter);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFilter(AgendaDateFilterType type, {DateTime? start, DateTime? end}) async {
    ref.read(agendaFilterProvider.notifier).state = AgendaFilterState(
      filterType: type,
      customStartDate: start,
      customEndDate: end,
    );
    // Riverpod watch akan memicu re-fetch otomatis
  }
}
