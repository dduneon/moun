import 'package:dio/dio.dart';
import '../domain/budget_models.dart';

class BudgetRepository {
  BudgetRepository(this._dio);
  final Dio _dio;

  Future<BudgetCycle> getCurrentCycle() async {
    final res = await _dio.get<Map<String, dynamic>>('/budget-cycles/current');
    return BudgetCycle.fromJson(res.data!);
  }

  Future<List<BudgetCycle>> listCycles({int count = 6}) async {
    final res = await _dio.get<List<dynamic>>('/budget-cycles', queryParameters: {'count': count});
    return (res.data!).map((e) => BudgetCycle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AvailableBudget> getCurrentBudget() async {
    final res = await _dio.get<Map<String, dynamic>>('/budget-cycles/current/budget');
    return AvailableBudget.fromJson(res.data!);
  }

  Future<AvailableBudget> getBudgetByDate({
    required DateTime startDate,
    required DateTime endDate,
    required String label,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/budget-cycles/by-date/budget',
      queryParameters: {
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'label': label,
      },
    );
    return AvailableBudget.fromJson(res.data!);
  }
}
