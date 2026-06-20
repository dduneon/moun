import 'package:dio/dio.dart';
import '../domain/transaction_models.dart';

class TransactionRepository {
  TransactionRepository(this._dio);
  final Dio _dio;

  Future<List<TransactionModel>> list({int? spendCycleId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/transactions',
      queryParameters: spendCycleId != null
          ? {'spend_cycle_id': spendCycleId}
          : null,
    );
    return (res.data!)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> create({
    required int amount,
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

  Future<void> delete(int id) async {
    await _dio.delete('/transactions/$id');
  }
}
