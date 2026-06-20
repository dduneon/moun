import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget_models.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.read(dioProvider));
});

final currentCycleProvider = FutureProvider<BudgetCycle>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(budgetRepositoryProvider).getCurrentCycle();
});

final availableBudgetProvider = FutureProvider<AvailableBudget>((ref) async {
  // currentCycleProvider를 watch해서 인증 상태 의존성 유지
  await ref.watch(currentCycleProvider.future);
  return ref.read(budgetRepositoryProvider).getCurrentBudget();
});

final cycleListProvider = FutureProvider<List<BudgetCycle>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(budgetRepositoryProvider).listCycles();
});
