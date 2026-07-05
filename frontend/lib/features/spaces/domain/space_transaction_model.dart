import 'package:flutter/foundation.dart';

@immutable
class SpaceTransactionModel {
  const SpaceTransactionModel({
    required this.id,
    this.name,
    required this.amount,
    required this.categoryId,
    required this.paymentMethod,
    required this.transactionDate,
    required this.billingDate,
    this.memo,
    this.sourceIncomeId,
    this.sourceFixedExpenseId,
    required this.createdByUserId,
  });

  final int id;
  final String? name;
  final double amount;
  final int categoryId;
  final String paymentMethod;
  final DateTime transactionDate;
  final DateTime billingDate;
  final String? memo;
  final int? sourceIncomeId;
  final int? sourceFixedExpenseId;
  final int createdByUserId;

  bool get isIncome => amount > 0;
  bool get isFromFixedSchedule => sourceIncomeId != null || sourceFixedExpenseId != null;

  factory SpaceTransactionModel.fromJson(Map<String, dynamic> json) => SpaceTransactionModel(
        id: json['id'] as int,
        name: json['name'] as String?,
        amount: double.parse(json['amount'].toString()),
        categoryId: json['category_id'] as int,
        paymentMethod: json['payment_method'] as String,
        transactionDate: DateTime.parse(json['transaction_date'] as String),
        billingDate: DateTime.parse(json['billing_date'] as String),
        memo: json['memo'] as String?,
        sourceIncomeId: json['source_income_id'] as int?,
        sourceFixedExpenseId: json['source_fixed_expense_id'] as int?,
        createdByUserId: json['created_by_user_id'] as int,
      );
}
