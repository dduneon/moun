import 'package:flutter/foundation.dart';

@immutable
class SpaceFixedIncomeItem {
  const SpaceFixedIncomeItem({
    required this.id,
    required this.name,
    required this.expectedAmount,
    this.scheduledDay,
    this.categoryId,
    required this.createdByUserId,
  });

  final int id;
  final String name;
  final double expectedAmount;
  final int? scheduledDay;
  final int? categoryId;
  final int createdByUserId;

  factory SpaceFixedIncomeItem.fromJson(Map<String, dynamic> j) => SpaceFixedIncomeItem(
        id: j['id'] as int,
        name: j['name'] as String,
        expectedAmount: double.parse((j['expected_amount'] ?? '0').toString()),
        scheduledDay: j['scheduled_day'] as int?,
        categoryId: j['category_id'] as int?,
        createdByUserId: j['created_by_user_id'] as int,
      );
}

@immutable
class SpaceFixedExpenseItem {
  const SpaceFixedExpenseItem({
    required this.id,
    required this.name,
    required this.amount,
    this.billingDay,
    this.categoryId,
    required this.isActive,
    required this.createdByUserId,
  });

  final int id;
  final String name;
  final double amount;
  final int? billingDay;
  final int? categoryId;
  final bool isActive;
  final int createdByUserId;

  factory SpaceFixedExpenseItem.fromJson(Map<String, dynamic> j) => SpaceFixedExpenseItem(
        id: j['id'] as int,
        name: j['name'] as String,
        amount: double.parse(j['amount'].toString()),
        billingDay: j['billing_day'] as int?,
        categoryId: j['category_id'] as int?,
        isActive: j['is_active'] as bool,
        createdByUserId: j['created_by_user_id'] as int,
      );
}
