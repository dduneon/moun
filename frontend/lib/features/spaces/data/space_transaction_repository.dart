import 'package:dio/dio.dart';
import '../domain/space_transaction_model.dart';

class SpaceTransactionRepository {
  SpaceTransactionRepository(this._dio);
  final Dio _dio;

  Future<List<SpaceTransactionModel>> list(
    int spaceId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['end_date'] = endDate.toIso8601String().substring(0, 10);

    final res = await _dio.get<List<dynamic>>(
      '/spaces/$spaceId/transactions',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (res.data!)
        .map((e) => SpaceTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpaceTransactionModel> create(
    int spaceId, {
    required int amount,
    required int categoryId,
    required String paymentMethod,
    required DateTime transactionDate,
    String? name,
    String? memo,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/spaces/$spaceId/transactions',
      data: {
        'amount': amount,
        'category_id': categoryId,
        'payment_method': paymentMethod,
        'transaction_date':
            '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
        if (name != null) 'name': name,
        if (memo != null) 'memo': memo,
      },
    );
    return SpaceTransactionModel.fromJson(res.data!);
  }

  Future<SpaceTransactionModel> update(
    int spaceId,
    int id, {
    int? amount,
    int? categoryId,
    DateTime? transactionDate,
    String? name,
    String? memo,
  }) async {
    final data = <String, dynamic>{
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (transactionDate != null)
        'transaction_date':
            '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
      if (name != null) 'name': name,
      if (memo != null) 'memo': memo,
    };
    final res = await _dio.patch<Map<String, dynamic>>('/spaces/$spaceId/transactions/$id', data: data);
    return SpaceTransactionModel.fromJson(res.data!);
  }

  Future<void> delete(int spaceId, int id) async {
    await _dio.delete<void>('/spaces/$spaceId/transactions/$id');
  }
}
