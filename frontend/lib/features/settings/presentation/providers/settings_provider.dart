import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(dioProvider));
});

final fixedIncomesProvider = FutureProvider<List<FixedIncomeItem>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(settingsRepositoryProvider).listIncomes();
});

final fixedExpensesProvider = FutureProvider<List<FixedExpenseItem>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(settingsRepositoryProvider).listFixedExpenses();
});
