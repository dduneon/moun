import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../budget/domain/budget_models.dart';
import '../../domain/space_model.dart';
import 'space_provider.dart';

/// 현재 선택된 Space의 이번 사이클. 개인 공간이 선택된 경우 null.
final currentSpaceCycleProvider = FutureProvider<BudgetCycle?>((ref) async {
  final context = await ref.watch(currentSpaceProvider.future);
  if (context is! SpaceSelected) return null;
  return ref.watch(spaceBudgetRepositoryProvider).getCurrentCycle(context.space.id);
});

/// 현재 선택된 Space의 가용 예산. 개인 공간이 선택된 경우 null.
final currentSpaceBudgetProvider = FutureProvider<AvailableBudget?>((ref) async {
  final context = await ref.watch(currentSpaceProvider.future);
  if (context is! SpaceSelected) return null;
  // currentSpaceCycleProvider를 watch해서 사이클 의존성 유지
  await ref.watch(currentSpaceCycleProvider.future);
  return ref.read(spaceBudgetRepositoryProvider).getCurrentBudget(context.space.id);
});
