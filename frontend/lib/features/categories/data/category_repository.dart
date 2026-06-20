import 'package:dio/dio.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> list() async {
    final res = await _dio.get<List<dynamic>>('/categories');
    return (res.data!)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> seedIfEmpty() async {
    final cats = await list();
    if (cats.isEmpty) {
      await _dio.post<void>('/auth/seed-categories');
    }
  }
}
