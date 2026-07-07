import 'package:dio/dio.dart';
import '../domain/transaction_models.dart';

class TransactionRepository {
  TransactionRepository(this._dio);
  final Dio _dio;

  Future<List<TransactionModel>> list({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['end_date'] = endDate.toIso8601String().substring(0, 10);

    final res = await _dio.get<List<dynamic>>(
      '/transactions',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (res.data!)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> create({
    required int amount,
    required TransactionType type,
    required int categoryId,
    required String paymentMethod,
    required DateTime transactionDate,
    String? name,
    String? memo,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: {
        'amount': amount,
        'type': type.apiValue,
        'category_id': categoryId,
        'payment_method': paymentMethod,
        'transaction_date':
            '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
        if (name != null) 'name': name,
        if (memo != null) 'memo': memo,
      },
    );
    return TransactionModel.fromJson(res.data!);
  }

  Future<TransactionModel> update(
    int id, {
    int? amount,
    TransactionType? type,
    int? categoryId,
    DateTime? transactionDate,
    String? name,
    String? memo,
  }) async {
    final data = <String, dynamic>{
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type.apiValue,
      if (categoryId != null) 'category_id': categoryId,
      if (transactionDate != null)
        'transaction_date':
            '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
      if (name != null) 'name': name,
      if (memo != null) 'memo': memo,
    };
    final res = await _dio.patch<Map<String, dynamic>>('/transactions/$id', data: data);
    return TransactionModel.fromJson(res.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/transactions/$id');
  }
}
