import 'package:flutter/foundation.dart';

@immutable
class SpaceFixedIncomeItem {
  const SpaceFixedIncomeItem({
    required this.id,
    required this.name,
    required this.expectedAmount,
    required this.frequency,
    this.scheduledDay,
    this.dayOfWeek,
    this.categoryId,
    required this.createdByUserId,
  });

  final int id;
  final String name;
  final double expectedAmount;
  final String frequency;
  final int? scheduledDay;
  final int? dayOfWeek;
  final int? categoryId;
  final int createdByUserId;

  factory SpaceFixedIncomeItem.fromJson(Map<String, dynamic> j) => SpaceFixedIncomeItem(
        id: j['id'] as int,
        name: j['name'] as String,
        expectedAmount: double.parse((j['expected_amount'] ?? '0').toString()),
        frequency: j['frequency'] as String? ?? 'monthly',
        scheduledDay: j['scheduled_day'] as int?,
        dayOfWeek: j['day_of_week'] as int?,
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
    required this.frequency,
    this.billingDay,
    this.dayOfWeek,
    this.categoryId,
    required this.isActive,
    required this.createdByUserId,
  });

  final int id;
  final String name;
  final double amount;
  final String frequency;
  final int? billingDay;
  final int? dayOfWeek;
  final int? categoryId;
  final bool isActive;
  final int createdByUserId;

  factory SpaceFixedExpenseItem.fromJson(Map<String, dynamic> j) => SpaceFixedExpenseItem(
        id: j['id'] as int,
        name: j['name'] as String,
        amount: double.parse(j['amount'].toString()),
        frequency: j['frequency'] as String? ?? 'monthly',
        billingDay: j['billing_day'] as int?,
        dayOfWeek: j['day_of_week'] as int?,
        categoryId: j['category_id'] as int?,
        isActive: j['is_active'] as bool,
        createdByUserId: j['created_by_user_id'] as int,
      );
}
