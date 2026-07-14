import 'package:flutter/foundation.dart';

/// 지역화폐/온누리 상품권 등 선불 충전형 결제수단.
/// 잔액(balance)은 백엔드에서 연결 거래의 delta 합으로 파생 계산된 값.
@immutable
class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.balance,
  });

  final int id;
  final String name;
  final bool isActive;
  final double balance;

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      balance: double.parse(json['balance'].toString()),
    );
  }
}
