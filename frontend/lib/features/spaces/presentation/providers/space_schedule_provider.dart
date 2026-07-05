import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/space_schedule_repository.dart';
import '../../domain/space_schedule_model.dart';

final spaceScheduleRepositoryProvider = Provider<SpaceScheduleRepository>((ref) {
  return SpaceScheduleRepository(ref.read(dioProvider));
});

final spaceFixedIncomesProvider =
    FutureProvider.family<List<SpaceFixedIncomeItem>, int>((ref, spaceId) async {
  return ref.watch(spaceScheduleRepositoryProvider).listIncomes(spaceId);
});

final spaceFixedExpensesProvider =
    FutureProvider.family<List<SpaceFixedExpenseItem>, int>((ref, spaceId) async {
  return ref.watch(spaceScheduleRepositoryProvider).listFixedExpenses(spaceId);
});

typedef SpaceMonthQuery = ({int spaceId, DateTime month});

/// 홈 화면 달력용 — 특정 달에 걸치는 고정수입/지출만 조회.
final spaceFixedIncomesForMonthProvider =
    FutureProvider.family<List<SpaceFixedIncomeItem>, SpaceMonthQuery>((ref, query) async {
  return ref.watch(spaceScheduleRepositoryProvider).listIncomes(query.spaceId, month: query.month);
});

final spaceFixedExpensesForMonthProvider =
    FutureProvider.family<List<SpaceFixedExpenseItem>, SpaceMonthQuery>((ref, query) async {
  return ref.watch(spaceScheduleRepositoryProvider).listFixedExpenses(query.spaceId, month: query.month);
});
