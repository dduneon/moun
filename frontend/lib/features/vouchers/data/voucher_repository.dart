import 'package:dio/dio.dart';
import '../domain/voucher_model.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class VoucherRepository {
  VoucherRepository(this._dio);
  final Dio _dio;

  Future<List<VoucherModel>> list() async {
    final res = await _dio.get<List<dynamic>>('/vouchers');
    return res.data!
        .map((e) => VoucherModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VoucherModel> create({required String name}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/vouchers',
      data: {'name': name},
    );
    return VoucherModel.fromJson(res.data!);
  }

  Future<VoucherModel> patch(int id, {String? name, bool? isActive}) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/vouchers/$id',
      data: {
        if (name != null) 'name': name,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return VoucherModel.fromJson(res.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/vouchers/$id');
  }

  /// 상품권 충전. paidAmount는 실제 지불액(예산 차감), faceAmount는 충전된 액면가
  /// (미지정 시 paidAmount와 동일 = 할인 없음).
  Future<VoucherModel> charge(
    int id, {
    required int paidAmount,
    int? faceAmount,
    required int categoryId,
    required DateTime transactionDate,
    String paymentMethod = 'account',
    String? name,
    String? memo,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/vouchers/$id/charge',
      data: {
        'paid_amount': paidAmount,
        if (faceAmount != null) 'face_amount': faceAmount,
        'category_id': categoryId,
        'transaction_date': _dateStr(transactionDate),
        'payment_method': paymentMethod,
        if (name != null) 'name': name,
        if (memo != null) 'memo': memo,
      },
    );
    return VoucherModel.fromJson(res.data!);
  }
}
