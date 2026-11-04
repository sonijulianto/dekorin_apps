import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';

class AgendaCalendarState {
  const AgendaCalendarState({
    required this.focusedMonth,
    required this.selectedDate,
    this.agendasByDateKey = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<String, List<AgendaItem>> agendasByDateKey;
  final bool isLoading;
  final String? errorMessage;

  AgendaCalendarState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    Map<String, List<AgendaItem>>? agendasByDateKey,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AgendaCalendarState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      agendasByDateKey: agendasByDateKey ?? this.agendasByDateKey,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<AgendaItem> get selectedDateAgendas {
    final key = dateKey(selectedDate);
    final items = agendasByDateKey[key] ?? const [];
    final sorted = List<AgendaItem>.from(items)
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
    return sorted;
  }

  List<AgendaItem> agendasForDate(DateTime date) {
    return agendasByDateKey[dateKey(date)] ?? const [];
  }
}

class AgendaCalendarNotifier extends StateNotifier<AgendaCalendarState> {
  AgendaCalendarNotifier(this._agendaService)
      : super(
          AgendaCalendarState(
            focusedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
            selectedDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          ),
        ) {
    loadMonth(state.focusedMonth);
  }

  final AgendaService _agendaService;

  Future<void> loadMonth(DateTime month) async {
    state = state.copyWith(isLoading: true, errorMessage: null, focusedMonth: month);

    try {
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final sundayOffset = firstDayOfMonth.weekday % 7; // Sunday = 0
      final gridStartDate = firstDayOfMonth.subtract(Duration(days: sundayOffset));
      final gridEndDate = gridStartDate.add(const Duration(days: 42));

      final agendas = await _agendaService.getAgendas(
        startDate: gridStartDate,
        endDate: gridEndDate,
      );

      final map = <String, List<AgendaItem>>{};
      for (final item in agendas) {
        final key = AgendaCalendarState.dateKey(item.eventDateTime);
        map.putIfAbsent(key, () => []).add(item);
      }

      state = state.copyWith(
        agendasByDateKey: map,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final isDifferentMonth = normalized.year != state.focusedMonth.year ||
        normalized.month != state.focusedMonth.month;

    state = state.copyWith(selectedDate: normalized);

    if (isDifferentMonth) {
      loadMonth(DateTime(normalized.year, normalized.month, 1));
    }
  }

  void previousMonth() {
    final prev = DateTime(state.focusedMonth.year, state.focusedMonth.month - 1, 1);
    loadMonth(prev);
  }

  void nextMonth() {
    final next = DateTime(state.focusedMonth.year, state.focusedMonth.month + 1, 1);
    loadMonth(next);
  }

  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    state = state.copyWith(selectedDate: today);
    if (now.year != state.focusedMonth.year || now.month != state.focusedMonth.month) {
      loadMonth(DateTime(now.year, now.month, 1));
    }
  }

  Future<void> refresh() async {
    await loadMonth(state.focusedMonth);
  }
}

final agendaCalendarViewModelProvider =
    StateNotifierProvider.autoDispose<AgendaCalendarNotifier, AgendaCalendarState>((ref) {
  final service = ref.watch(agendaServiceProvider);
  return AgendaCalendarNotifier(service);
});
