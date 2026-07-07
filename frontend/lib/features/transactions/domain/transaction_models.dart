import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  expense,
  saving;

  String get apiValue => name;

  static TransactionType fromApi(String? value, {required double amount}) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'saving':
        return TransactionType.saving;
      case 'expense':
        return TransactionType.expense;
      default:
        // 구버전 응답 등 type이 없는 경우 금액 부호로 추론
        return amount > 0 ? TransactionType.income : TransactionType.expense;
    }
  }
}

@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.paymentMethod,
    this.cardId,
    required this.transactionDate,
    required this.billingDate,
    this.memo,
    this.sourceIncomeId,
    this.sourceFixedExpenseId,
  });

  final int id;
  final String? name;
  final double amount;
  final TransactionType type;
  final int categoryId;
  final String paymentMethod;
  final int? cardId;
  final DateTime transactionDate;
  final DateTime billingDate;
  final String? memo;
  final int? sourceIncomeId;
  final int? sourceFixedExpenseId;

  bool get isIncome => type == TransactionType.income;
  bool get isSaving => type == TransactionType.saving;
  bool get isFromFixedSchedule =>
      sourceIncomeId != null || sourceFixedExpenseId != null;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amount = double.parse(json['amount'].toString());
    return TransactionModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      amount: amount,
      type: TransactionType.fromApi(json['type'] as String?, amount: amount),
      categoryId: json['category_id'] as int,
      paymentMethod: json['payment_method'] as String,
      cardId: json['card_id'] as int?,
      transactionDate:
          DateTime.parse(json['transaction_date'] as String),
      billingDate: DateTime.parse(json['billing_date'] as String),
      memo: json['memo'] as String?,
      sourceIncomeId: json['source_income_id'] as int?,
      sourceFixedExpenseId: json['source_fixed_expense_id'] as int?,
    );
  }
}
