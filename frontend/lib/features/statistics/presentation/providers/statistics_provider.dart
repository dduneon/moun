import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../budget/domain/budget_models.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../transactions/domain/transaction_models.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../../shared/widgets/charts/spending_line_chart.dart';

/// 최근 사이클별 예산 데이터 (사이클 비교 탭용)
final allCycleBudgetsProvider = FutureProvider<List<AvailableBudget>>((ref) async {
  final cycles = await ref.watch(cycleListProvider.future);
  final repo = ref.read(budgetRepositoryProvider);
  return Future.wait(
    cycles.map((c) => repo.getBudgetByDate(
          startDate: c.startDate,
          endDate: c.endDate,
          label: c.label,
        )),
  );
});

/// 현재 사이클의 일별 누적 지출 포인트
final dailySpendingPointsProvider = FutureProvider<List<SpendingPoint>>((ref) async {
  final cycle = await ref.watch(currentCycleProvider.future);
  final txns = await ref.watch(currentCycleTransactionsProvider.future);

  final expenseByDay = <int, int>{};
  for (final t in txns) {
    if (t.type != TransactionType.expense) continue;
    final day = t.transactionDate.difference(cycle.startDate).inDays + 1;
    if (day < 1) continue;
    expenseByDay[day] = (expenseByDay[day] ?? 0) + t.amount.abs().round();
  }

  if (expenseByDay.isEmpty) return const [];

  final sortedDays = expenseByDay.keys.toList()..sort();
  var cumulative = 0;
  return sortedDays.map((day) {
    cumulative += expenseByDay[day]!;
    return SpendingPoint(day: day, amount: cumulative);
  }).toList();
});
