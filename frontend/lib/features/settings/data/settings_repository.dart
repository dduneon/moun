import 'package:dio/dio.dart';

class FixedIncomeItem {
  const FixedIncomeItem({
    required this.id,
    required this.name,
    required this.expectedAmount,
    this.scheduledDay,
    required this.groupId,
    required this.effectiveFrom,
  });

  final int id;
  final String name;
  final double expectedAmount;
  final int? scheduledDay;
  final int groupId;
  final DateTime effectiveFrom;

  factory FixedIncomeItem.fromJson(Map<String, dynamic> j) => FixedIncomeItem(
        id: j['id'] as int,
        name: j['name'] as String,
        expectedAmount: double.parse((j['expected_amount'] ?? '0').toString()),
        scheduledDay: j['scheduled_day'] as int?,
        groupId: (j['group_id'] as int?) ?? (j['id'] as int),
        effectiveFrom: DateTime.parse(j['effective_from'] as String? ?? '2000-01-01'),
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
    required this.groupId,
    required this.effectiveFrom,
  });

  final int id;
  final String name;
  final double amount;
  final int billingDay;
  final String paymentMethod;
  final bool isActive;
  final int groupId;
  final DateTime effectiveFrom;

  factory FixedExpenseItem.fromJson(Map<String, dynamic> j) => FixedExpenseItem(
        id: j['id'] as int,
        name: j['name'] as String,
        amount: double.parse(j['amount'].toString()),
        billingDay: j['billing_day'] as int,
        paymentMethod: j['payment_method'] as String,
        isActive: j['is_active'] as bool,
        groupId: (j['group_id'] as int?) ?? (j['id'] as int),
        effectiveFrom: DateTime.parse(j['effective_from'] as String? ?? '2000-01-01'),
      );
}

class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  // ── Fixed Incomes ─────────────────────────────
  Future<List<FixedIncomeItem>> listIncomes({DateTime? month}) async {
    final params = month != null
        ? {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01'}
        : null;
    final res = await _dio.get<List<dynamic>>('/incomes', queryParameters: params);
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

  Future<void> updateIncome(int id, {String? name, double? amount, int? scheduledDay, DateTime? effectiveFrom}) =>
      _dio.patch<void>('/incomes/$id', data: {
        if (name != null) 'name': name,
        if (amount != null) 'expected_amount': amount,
        if (scheduledDay != null) 'scheduled_day': scheduledDay,
        if (effectiveFrom != null)
          'effective_from': '${effectiveFrom.year}-${effectiveFrom.month.toString().padLeft(2, '0')}-01',
      });

  Future<void> deleteIncome(int id, {DateTime? endFrom}) => _dio.delete<void>(
        '/incomes/$id',
        data: {
          'end_from': endFrom != null
              ? '${endFrom.year}-${endFrom.month.toString().padLeft(2, '0')}-01'
              : null,
        },
      );

  // ── Fixed Expenses ────────────────────────────
  Future<List<FixedExpenseItem>> listFixedExpenses({DateTime? month}) async {
    final params = month != null
        ? {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01'}
        : null;
    final res = await _dio.get<List<dynamic>>('/fixed-expenses', queryParameters: params);
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

  Future<void> updateFixedExpense(int id, {String? name, double? amount, int? billingDay, String? paymentMethod, DateTime? effectiveFrom}) =>
      _dio.patch<void>('/fixed-expenses/$id', data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (billingDay != null) 'billing_day': billingDay,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (effectiveFrom != null)
          'effective_from': '${effectiveFrom.year}-${effectiveFrom.month.toString().padLeft(2, '0')}-01',
      });

  Future<void> deleteFixedExpense(int id, {DateTime? endFrom}) => _dio.delete<void>(
        '/fixed-expenses/$id',
        data: {
          'end_from': endFrom != null
              ? '${endFrom.year}-${endFrom.month.toString().padLeft(2, '0')}-01'
              : null,
        },
      );

  Future<void> toggleFixedExpense(int id, bool isActive) =>
      _dio.patch<void>('/fixed-expenses/$id', data: {'is_active': isActive});

  // ── User settings ─────────────────────────────
  Future<Map<String, dynamic>> updateSalaryDay(int day) async {
    final res = await _dio.patch<Map<String, dynamic>>('/auth/me', data: {'salary_day': day});
    return res.data!;
  }
}
