import 'package:dio/dio.dart';
import '../../budget/domain/budget_models.dart';

class SpaceBudgetRepository {
  SpaceBudgetRepository(this._dio);
  final Dio _dio;

  Future<BudgetCycle> getCurrentCycle(int spaceId) async {
    final res = await _dio.get<Map<String, dynamic>>('/spaces/$spaceId/budget-cycles/current');
    return BudgetCycle.fromJson(res.data!);
  }

  Future<List<BudgetCycle>> listCycles(int spaceId, {int count = 6}) async {
    final res = await _dio.get<List<dynamic>>(
      '/spaces/$spaceId/budget-cycles',
      queryParameters: {'count': count},
    );
    return (res.data!).map((e) => BudgetCycle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AvailableBudget> getCurrentBudget(int spaceId) async {
    final res = await _dio.get<Map<String, dynamic>>('/spaces/$spaceId/budget-cycles/current/budget');
    return AvailableBudget.fromJson(res.data!);
  }
}
