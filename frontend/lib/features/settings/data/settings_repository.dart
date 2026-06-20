import 'package:dio/dio.dart';

class FixedIncomeItem {
  const FixedIncomeItem({
    required this.id,
    required this.name,
    required this.expectedAmount,
    this.scheduledDay,
  });

  final int id;
  final String name;
  final double expectedAmount;
  final int? scheduledDay;

  factory FixedIncomeItem.fromJson(Map<String, dynamic> j) => FixedIncomeItem(
        id: j['id'] as int,
        name: j['name'] as String,
        expectedAmount: double.parse((j['expected_amount'] ?? '0').toString()),
        scheduledDay: j['scheduled_day'] as int?,
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

  // ── Fixed Incomes ─────────────────────────────
  Future<List<FixedIncomeItem>> listIncomes() async {
    final res = await _dio.get<List<dynamic>>('/incomes');
    return (res.data!).map((e) => FixedIncomeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FixedIncomeItem> createIncome({
    required String name,
    required double amount,
    int? scheduledDay,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/incomes', data: {
      'name': name,
      'expected_amount': amount,
      if (scheduledDay != null) 'scheduled_day': scheduledDay,
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

  // ── User settings ─────────────────────────────
  Future<Map<String, dynamic>> updateSalaryDay(int day) async {
    final res = await _dio.patch<Map<String, dynamic>>('/auth/me', data: {'salary_day': day});
    return res.data!;
  }
}
