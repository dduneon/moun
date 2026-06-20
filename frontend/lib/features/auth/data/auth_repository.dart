import 'package:dio/dio.dart';
import '../domain/auth_model.dart';

abstract class AuthRepository {
  Future<({String accessToken, String refreshToken})> login({
    required String email,
    required String password,
    String deviceId,
  });

  Future<({String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String name,
  });

  Future<String> refresh(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<AuthUser> getMe();
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<({String accessToken, String refreshToken})> login({
    required String email,
    required String password,
    String deviceId = 'mobile',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_id': deviceId},
    );
    return (
      accessToken: res.data!['access_token'] as String,
      refreshToken: res.data!['refresh_token'] as String,
    );
  }

  @override
  Future<({String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await _dio.post<void>(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    return login(email: email, password: password);
  }

  @override
  Future<String> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );
    return res.data!['access_token'] as String;
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }

  @override
  Future<AuthUser> getMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(res.data!);
  }
}
