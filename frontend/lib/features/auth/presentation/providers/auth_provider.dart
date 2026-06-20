import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_model.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(ref.read(dioProvider));
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthStateUnauthenticated();

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  /// 앱 시작 시 저장된 토큰으로 세션 복원.
  Future<void> restoreSession() async {
    state = const AuthStateAuthenticating();
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        state = const AuthStateUnauthenticated();
        return;
      }
      final user = await _repo.getMe();
      state = AuthStateAuthenticated(user);
    } catch (_) {
      await _storage.clearTokens();
      state = const AuthStateUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthStateAuthenticating();
    try {
      final tokens = await _repo.login(email: email, password: password);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final user = await _repo.getMe();
      state = AuthStateAuthenticated(user);
    } on DioException catch (e) {
      state = const AuthStateUnauthenticated();
      throw _mapDioError(e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AuthStateAuthenticating();
    try {
      final tokens = await _repo.register(
        email: email,
        password: password,
        name: name,
      );
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final user = await _repo.getMe();
      state = AuthStateAuthenticated(user);
    } on DioException catch (e) {
      state = const AuthStateUnauthenticated();
      throw _mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _repo.logout(refreshToken);
      }
    } catch (_) {
      // 로그아웃은 서버 실패해도 로컬 처리
    } finally {
      await _storage.clearTokens();
      state = const AuthStateUnauthenticated();
    }
  }

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return '이메일 또는 비밀번호가 올바르지 않습니다';
    if (status == 409) return '이미 사용 중인 이메일입니다';
    if (status == 429) return '잠시 후 다시 시도해주세요';
    return '네트워크 오류가 발생했습니다';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
