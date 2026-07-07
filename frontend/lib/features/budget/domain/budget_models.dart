import 'package:flutter/foundation.dart';

@immutable
class BudgetCycle {
  const BudgetCycle({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String label;

  factory BudgetCycle.fromJson(Map<String, dynamic> json) => BudgetCycle(
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        label: json['label'] as String,
      );
}

@immutable
class CategoryAmount {
  const CategoryAmount({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });

  final int categoryId;
  final String categoryName;
  final double total;

  factory CategoryAmount.fromJson(Map<String, dynamic> json) => CategoryAmount(
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
        total: double.parse(json['total'].toString()),
      );
}

@immutable
class SpendSummary {
  const SpendSummary({
    required this.totalSpend,
    required this.byCategory,
  });

  final double totalSpend;
  final List<CategoryAmount> byCategory;

  factory SpendSummary.fromJson(Map<String, dynamic> json) => SpendSummary(
        totalSpend: double.parse(json['total_spend'].toString()),
        byCategory: (json['by_category'] as List)
            .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class BillingSummary {
  const BillingSummary({
    required this.totalBilling,
    required this.byCategory,
  });

  final double totalBilling;
  final List<CategoryAmount> byCategory;

  factory BillingSummary.fromJson(Map<String, dynamic> json) => BillingSummary(
        totalBilling: double.parse(json['total_billing'].toString()),
        byCategory: (json['by_category'] as List)
            .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class SavingSummary {
  const SavingSummary({
    required this.totalSaving,
    required this.byCategory,
  });

  final double totalSaving;
  final List<CategoryAmount> byCategory;

  factory SavingSummary.fromJson(Map<String, dynamic> json) => SavingSummary(
        totalSaving: double.parse(json['total_saving'].toString()),
        byCategory: (json['by_category'] as List)
            .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class AvailableBudget {
  const AvailableBudget({
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.confirmedIncome,
    required this.expectedIncome,
    required this.fixedExpense,
    required this.confirmedFixedExpense,
    required this.billedTransactions,
    required this.confirmedSaving,
    required this.pendingSaving,
    required this.available,
    required this.spendSummary,
    required this.billingSummary,
    required this.savingSummary,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final double confirmedIncome;
  final double expectedIncome;
  final double fixedExpense;           // 미청구 예정 고정지출
  final double confirmedFixedExpense;  // 이미 실행된 고정지출
  final double billedTransactions;
  final double confirmedSaving;        // 이미 실행된 저축/이체
  final double pendingSaving;           // 미청구 예정 고정저축
  final double available;
  final SpendSummary spendSummary;
  final BillingSummary billingSummary;
  final SavingSummary savingSummary;

  double get totalSpent => spendSummary.totalSpend.abs();
  double get totalFixedExpense => confirmedFixedExpense.abs() + fixedExpense;
  double get variableExpense => (totalSpent - confirmedFixedExpense.abs()).clamp(0, double.infinity);
  double get totalSaving => confirmedSaving.abs() + pendingSaving;
  bool get hasPendingIncome => confirmedIncome < expectedIncome;

  /// 확정된 지출 + 아직 청구되지 않은 예정 고정지출까지 합산한 총 지출.
  double get totalSpentWithPending => totalSpent + fixedExpense;
  bool get hasPendingFixedExpense => fixedExpense > 0;

  factory AvailableBudget.fromJson(Map<String, dynamic> json) => AvailableBudget(
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        label: json['label'] as String,
        confirmedIncome: double.parse(json['confirmed_income'].toString()),
        expectedIncome: double.parse(json['expected_income'].toString()),
        fixedExpense: double.parse(json['fixed_expense'].toString()),
        confirmedFixedExpense: double.parse(json['confirmed_fixed_expense'].toString()),
        billedTransactions: double.parse(json['billed_transactions'].toString()),
        confirmedSaving: double.parse(json['confirmed_saving'].toString()),
        pendingSaving: double.parse(json['pending_saving'].toString()),
        available: double.parse(json['available'].toString()),
        spendSummary: SpendSummary.fromJson(
            json['spend_summary'] as Map<String, dynamic>),
        billingSummary: BillingSummary.fromJson(
            json['billing_summary'] as Map<String, dynamic>),
        savingSummary: SavingSummary.fromJson(
            json['saving_summary'] as Map<String, dynamic>),
      );
}
