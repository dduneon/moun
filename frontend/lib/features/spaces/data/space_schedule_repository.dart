import 'package:dio/dio.dart';
import '../domain/space_schedule_model.dart';

/// Space 고정수입/고정지출 — 개인용 대비 간소화된 버전 (월별 반복만 지원,
/// 수정 없이 추가/삭제만 가능. 좀 더 정교한 반복 주기·버전 관리가 필요해지면
/// 개인용 SettingsRepository 패턴을 참고해 확장하면 된다).
class SpaceScheduleRepository {
  SpaceScheduleRepository(this._dio);
  final Dio _dio;

  Future<List<SpaceFixedIncomeItem>> listIncomes(int spaceId, {DateTime? month}) async {
    final params = month != null
        ? {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01'}
        : null;
    final res = await _dio.get<List<dynamic>>('/spaces/$spaceId/incomes', queryParameters: params);
    return (res.data!).map((e) => SpaceFixedIncomeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SpaceFixedIncomeItem> createIncome(
    int spaceId, {
    required String name,
    required double amount,
    required int scheduledDay,
    int? categoryId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/spaces/$spaceId/incomes', data: {
      'name': name,
      'expected_amount': amount,
      'frequency': 'monthly',
      'scheduled_day': scheduledDay,
      if (categoryId != null) 'category_id': categoryId,
      'include_current_cycle': true,
    });
    return SpaceFixedIncomeItem.fromJson(res.data!);
  }

  Future<void> deleteIncome(int spaceId, int id) =>
      _dio.delete<void>('/spaces/$spaceId/incomes/$id', data: {'end_from': null});

  Future<List<SpaceFixedExpenseItem>> listFixedExpenses(int spaceId, {DateTime? month}) async {
    final params = month != null
        ? {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01'}
        : null;
    final res = await _dio.get<List<dynamic>>('/spaces/$spaceId/fixed-expenses', queryParameters: params);
    return (res.data!).map((e) => SpaceFixedExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SpaceFixedExpenseItem> createFixedExpense(
    int spaceId, {
    required String name,
    required double amount,
    required int billingDay,
    int? categoryId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/spaces/$spaceId/fixed-expenses', data: {
      'name': name,
      'amount': amount,
      'frequency': 'monthly',
      'billing_day': billingDay,
      'payment_method': 'account',
      if (categoryId != null) 'category_id': categoryId,
      'include_current_cycle': true,
    });
    return SpaceFixedExpenseItem.fromJson(res.data!);
  }

  Future<void> deleteFixedExpense(int spaceId, int id) =>
      _dio.delete<void>('/spaces/$spaceId/fixed-expenses/$id', data: {'end_from': null});
}
