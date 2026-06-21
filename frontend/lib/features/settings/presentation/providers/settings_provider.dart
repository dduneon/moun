import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(dioProvider));
});

// month=null → 설정 화면 (현재 활성 버전)
// month=DateTime → 홈 캘린더 (해당 달 기준 버전)
final fixedIncomesProvider =
    FutureProvider.family<List<FixedIncomeItem>, DateTime?>((ref, month) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(settingsRepositoryProvider).listIncomes(month: month);
});

final fixedExpensesProvider =
    FutureProvider.family<List<FixedExpenseItem>, DateTime?>((ref, month) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(settingsRepositoryProvider).listFixedExpenses(month: month);
});
