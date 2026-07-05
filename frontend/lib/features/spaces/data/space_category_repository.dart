import 'package:dio/dio.dart';
import '../domain/space_category_model.dart';

class SpaceCategoryRepository {
  SpaceCategoryRepository(this._dio);
  final Dio _dio;

  Future<List<SpaceCategoryModel>> list(int spaceId) async {
    final res = await _dio.get<List<dynamic>>('/spaces/$spaceId/categories');
    return (res.data!)
        .map((e) => SpaceCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpaceCategoryModel> create(int spaceId, {required String name, String? icon}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/spaces/$spaceId/categories',
      data: {'name': name, if (icon != null) 'icon': icon},
    );
    return SpaceCategoryModel.fromJson(res.data!);
  }

  Future<void> delete(int spaceId, int categoryId) async {
    await _dio.delete<void>('/spaces/$spaceId/categories/$categoryId');
  }
}
