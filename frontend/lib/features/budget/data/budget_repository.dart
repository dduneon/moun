import 'package:dio/dio.dart';
import '../domain/budget_models.dart';

class BudgetRepository {
  BudgetRepository(this._dio);
  final Dio _dio;

  Future<BudgetCycle> getCurrentCycle() async {
    final res = await _dio.get<Map<String, dynamic>>('/budget-cycles/current');
    return BudgetCycle.fromJson(res.data!);
  }

  Future<List<BudgetCycle>> listCycles() async {
    final res = await _dio.get<List<dynamic>>('/budget-cycles');
    return (res.data!).map((e) => BudgetCycle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AvailableBudget> getAvailableBudget(int cycleId) async {
    final res = await _dio.get<Map<String, dynamic>>('/budget-cycles/$cycleId/budget');
    return AvailableBudget.fromJson(res.data!);
  }
}
