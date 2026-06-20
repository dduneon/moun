import 'package:flutter/foundation.dart';

@immutable
class BudgetCycle {
  const BudgetCycle({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.salaryExpected,
    this.salaryActual,
  });

  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final double salaryExpected;
  final double? salaryActual;

  double get salary => salaryActual ?? salaryExpected;

  factory BudgetCycle.fromJson(Map<String, dynamic> json) => BudgetCycle(
        id: json['id'] as int,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        label: json['label'] as String,
        salaryExpected: double.parse(json['salary_expected'].toString()),
        salaryActual: json['salary_actual'] != null
            ? double.parse(json['salary_actual'].toString())
            : null,
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
    required this.cycleId,
    required this.totalSpend,
    required this.byCategory,
  });

  final int cycleId;
  final double totalSpend;
  final List<CategoryAmount> byCategory;

  factory SpendSummary.fromJson(Map<String, dynamic> json) => SpendSummary(
        cycleId: json['cycle_id'] as int,
        totalSpend: double.parse(json['total_spend'].toString()),
        byCategory: (json['by_category'] as List)
            .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class BillingSummary {
  const BillingSummary({
    required this.cycleId,
    required this.totalBilling,
    required this.byCategory,
  });

  final int cycleId;
  final double totalBilling;
  final List<CategoryAmount> byCategory;

  factory BillingSummary.fromJson(Map<String, dynamic> json) => BillingSummary(
        cycleId: json['cycle_id'] as int,
        totalBilling: double.parse(json['total_billing'].toString()),
        byCategory: (json['by_category'] as List)
            .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class AvailableBudget {
  const AvailableBudget({
    required this.cycleId,
    required this.salary,
    required this.extraIncome,
    required this.fixedExpense,
    required this.billedTransactions,
    required this.available,
    required this.spendSummary,
    required this.billingSummary,
  });

  final int cycleId;
  final double salary;
  final double extraIncome;
  final double fixedExpense;
  final double billedTransactions;
  final double available;
  final SpendSummary spendSummary;
  final BillingSummary billingSummary;

  double get totalIncome => salary + extraIncome;
  double get totalSpent => spendSummary.totalSpend.abs();

  factory AvailableBudget.fromJson(Map<String, dynamic> json) => AvailableBudget(
        cycleId: json['cycle_id'] as int,
        salary: double.parse(json['salary'].toString()),
        extraIncome: double.parse(json['extra_income'].toString()),
        fixedExpense: double.parse(json['fixed_expense'].toString()),
        billedTransactions: double.parse(json['billed_transactions'].toString()),
        available: double.parse(json['available'].toString()),
        spendSummary: SpendSummary.fromJson(
            json['spend_summary'] as Map<String, dynamic>),
        billingSummary: BillingSummary.fromJson(
            json['billing_summary'] as Map<String, dynamic>),
      );
}
