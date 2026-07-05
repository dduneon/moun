import 'package:dio/dio.dart';
import '../domain/space_model.dart';

class SpaceRepository {
  SpaceRepository(this._dio);
  final Dio _dio;

  Future<List<SpaceModel>> listMySpaces() async {
    final res = await _dio.get<List<dynamic>>('/spaces');
    return (res.data!)
        .map((e) => SpaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpaceModel> getSpace(int spaceId) async {
    final res = await _dio.get<Map<String, dynamic>>('/spaces/$spaceId');
    return SpaceModel.fromJson(res.data!);
  }

  Future<SpaceModel> createSpace({required String name, int baseDay = 1}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/spaces',
      data: {'name': name, 'base_day': baseDay},
    );
    return SpaceModel.fromJson(res.data!);
  }

  Future<SpaceModel> updateSpaceName(int spaceId, String name) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/spaces/$spaceId',
      data: {'name': name},
    );
    return SpaceModel.fromJson(res.data!);
  }

  Future<void> leaveSpace(int spaceId) async {
    await _dio.delete<void>('/spaces/$spaceId/members/me');
  }

  Future<List<SpaceMemberModel>> listMembers(int spaceId) async {
    final res = await _dio.get<List<dynamic>>('/spaces/$spaceId/members');
    return (res.data!)
        .map((e) => SpaceMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeMember(int spaceId, int userId) async {
    await _dio.delete<void>('/spaces/$spaceId/members/$userId');
  }

  Future<SpaceInviteModel> createInvite(int spaceId) async {
    final res = await _dio.post<Map<String, dynamic>>('/spaces/$spaceId/invites');
    return SpaceInviteModel.fromJson(res.data!);
  }

  /// 초대 미리보기는 로그인 없이도 열람 가능해야 하므로 skipAuth.
  Future<SpaceInvitePreviewModel> previewInvite(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/spaces/invites/$token',
      options: Options(extra: {'skipAuth': true}),
    );
    return SpaceInvitePreviewModel.fromJson(res.data!);
  }

  Future<SpaceModel> acceptInvite(String token) async {
    final res = await _dio.post<Map<String, dynamic>>('/spaces/invites/$token/accept');
    return SpaceModel.fromJson(res.data!);
  }
}
