import 'package:flutter/foundation.dart';

@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.name,
    required this.amount,
    required this.categoryId,
    required this.paymentMethod,
    this.cardId,
    required this.transactionDate,
    required this.billingDate,
    this.memo,
  });

  final int id;
  final String? name;
  final double amount;
  final int categoryId;
  final String paymentMethod;
  final int? cardId;
  final DateTime transactionDate;
  final DateTime billingDate;
  final String? memo;

  bool get isIncome => amount > 0;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as int,
        name: json['name'] as String?,
        amount: double.parse(json['amount'].toString()),
        categoryId: json['category_id'] as int,
        paymentMethod: json['payment_method'] as String,
        cardId: json['card_id'] as int?,
        transactionDate:
            DateTime.parse(json['transaction_date'] as String),
        billingDate: DateTime.parse(json['billing_date'] as String),
        memo: json['memo'] as String?,
      );
}
