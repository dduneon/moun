import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(dioProvider));
});

final userSettingProvider = FutureProvider<UserSetting>((ref) {
  return ref.watch(settingsRepositoryProvider).getSetting();
});

final fixedIncomesProvider = FutureProvider<List<FixedIncomeItem>>((ref) {
  return ref.watch(settingsRepositoryProvider).listIncomes();
});

final fixedExpensesProvider = FutureProvider<List<FixedExpenseItem>>((ref) {
  return ref.watch(settingsRepositoryProvider).listFixedExpenses();
});
