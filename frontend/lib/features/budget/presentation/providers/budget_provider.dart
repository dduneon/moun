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
  // 인증 완료 전에는 API 호출하지 않음 (세션 복원 중 401 방지)
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(budgetRepositoryProvider).getCurrentCycle();
});

final availableBudgetProvider = FutureProvider<AvailableBudget>((ref) async {
  final cycle = await ref.watch(currentCycleProvider.future);
  return ref.read(budgetRepositoryProvider).getAvailableBudget(cycle.id);
});

final cycleListProvider = FutureProvider<List<BudgetCycle>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(budgetRepositoryProvider).listCycles();
});
