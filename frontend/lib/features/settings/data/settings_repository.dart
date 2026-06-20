import 'package:dio/dio.dart';

class UserSetting {
  const UserSetting({
    required this.salaryDay,
    required this.paydayAdjustment,
    required this.holidayCountry,
  });

  final int salaryDay;
  final String paydayAdjustment;
  final String holidayCountry;

  factory UserSetting.fromJson(Map<String, dynamic> j) => UserSetting(
        salaryDay: j['salary_day'] as int,
        paydayAdjustment: j['payday_adjustment'] as String,
        holidayCountry: j['holiday_country'] as String,
      );

  static const defaultSetting = UserSetting(
    salaryDay: 21,
    paydayAdjustment: 'prev_business',
    holidayCountry: 'KR',
  );
}

class FixedIncomeItem {
  const FixedIncomeItem({
    required this.id,
    required this.name,
    required this.expectedAmount,
    required this.scheduledDay,
    required this.type,
  });

  final int id;
  final String name;
  final double expectedAmount;
  final int? scheduledDay;
  final String type; // 'salary' | 'extra'

  factory FixedIncomeItem.fromJson(Map<String, dynamic> j) => FixedIncomeItem(
        id: j['id'] as int,
        name: j['name'] as String,
        expectedAmount: double.parse((j['expected_amount'] ?? '0').toString()),
        scheduledDay: j['scheduled_day'] as int?,
        type: j['type'] as String,
      );
}

class FixedExpenseItem {
  const FixedExpenseItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.paymentMethod,
    required this.isActive,
  });

  final int id;
  final String name;
  final double amount;
  final int billingDay;
  final String paymentMethod;
  final bool isActive;

  factory FixedExpenseItem.fromJson(Map<String, dynamic> j) => FixedExpenseItem(
        id: j['id'] as int,
        name: j['name'] as String,
        amount: double.parse(j['amount'].toString()),
        billingDay: j['billing_day'] as int,
        paymentMethod: j['payment_method'] as String,
        isActive: j['is_active'] as bool,
      );
}

class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  // ── UserSetting ───────────────────────────────
  Future<UserSetting> getSetting() async {
    final res = await _dio.get<Map<String, dynamic>>('/settings');
    return UserSetting.fromJson(res.data!);
  }

  Future<UserSetting> patchSetting(Map<String, dynamic> data) async {
    final res = await _dio.patch<Map<String, dynamic>>('/settings', data: data);
    return UserSetting.fromJson(res.data!);
  }

  // ── Fixed Incomes ─────────────────────────────
  Future<List<FixedIncomeItem>> listIncomes() async {
    final res = await _dio.get<List<dynamic>>('/incomes');
    return (res.data!).map((e) => FixedIncomeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FixedIncomeItem> createIncome({
    required String name,
    required double amount,
    required String type,
    int? scheduledDay,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/incomes', data: {
      'name': name,
      'type': type,
      'expected_amount': amount,
      if (scheduledDay != null) 'scheduled_day': scheduledDay,
      'status': 'pending',
    });
    return FixedIncomeItem.fromJson(res.data!);
  }

  Future<void> deleteIncome(int id) => _dio.delete<void>('/incomes/$id');

  // ── Fixed Expenses ────────────────────────────
  Future<List<FixedExpenseItem>> listFixedExpenses() async {
    final res = await _dio.get<List<dynamic>>('/fixed-expenses');
    return (res.data!).map((e) => FixedExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FixedExpenseItem> createFixedExpense({
    required String name,
    required double amount,
    required int billingDay,
    String paymentMethod = 'account',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/fixed-expenses', data: {
      'name': name,
      'amount': amount,
      'billing_day': billingDay,
      'payment_method': paymentMethod,
    });
    return FixedExpenseItem.fromJson(res.data!);
  }

  Future<void> deleteFixedExpense(int id) => _dio.delete<void>('/fixed-expenses/$id');

  Future<void> toggleFixedExpense(int id, bool isActive) =>
      _dio.patch<void>('/fixed-expenses/$id', data: {'is_active': isActive});
}
