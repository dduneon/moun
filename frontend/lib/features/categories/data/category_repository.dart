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

  // 서버의 /auth/seed-categories는 없는 기본 카테고리만 채워주는 멱등 엔드포인트라
  // 매번 호출해도 안전하다. 기존 계정에 새로 추가된 기본 카테고리(예: "저축")가
  // 누락되는 것을 막기 위해 카테고리가 이미 있어도 항상 호출한다.
  Future<void> seedIfEmpty() async {
    await _dio.post<void>('/auth/seed-categories');
  }
}
