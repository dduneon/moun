import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_model.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

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

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthStateUnauthenticated();
      return;
    }

    // access token이 만료됐을 수 있으므로 먼저 refresh를 시도한다.
    try {
      final newAccessToken = await _repo.refresh(refreshToken);
      await _storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );
    } on DioException {
      // refresh 실패 = refresh token 만료 또는 서버 오류 → 로그아웃
      await _storage.clearTokens();
      state = const AuthStateUnauthenticated();
      return;
    }

    try {
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

  Future<void> loginWithKakao() async {
    state = const AuthStateAuthenticating();
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final tokens = await _repo.kakaoLogin(
        kakaoAccessToken: token.accessToken,
      );
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final user = await _repo.getMe();
      state = AuthStateAuthenticated(user, needsOnboarding: tokens.isNewUser);
    } on KakaoAuthException catch (e) {
      state = const AuthStateUnauthenticated();
      if (e.error == AuthErrorCause.accessDenied) {
        throw '카카오 로그인이 취소되었습니다';
      }
      throw '카카오 로그인에 실패했습니다';
    } on DioException catch (e) {
      state = const AuthStateUnauthenticated();
      throw _mapDioError(e);
    } catch (_) {
      state = const AuthStateUnauthenticated();
      throw '카카오 로그인에 실패했습니다';
    }
  }

  void completeOnboarding() {
    final current = state;
    if (current is AuthStateAuthenticated) {
      state = AuthStateAuthenticated(current.user);
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
      state = AuthStateAuthenticated(user, needsOnboarding: true);
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

  Future<void> updateSalaryDay(int day) async {
    final current = state;
    if (current is! AuthStateAuthenticated) return;
    await ref.read(settingsRepositoryProvider).updateSalaryDay(day);
    state = AuthStateAuthenticated(current.user.copyWith(salaryDay: day));
  }

  String _mapDioError(DioException e) {
    debugPrint('[Auth] DioException type: ${e.type}');
    debugPrint('[Auth] DioException message: ${e.message}');
    debugPrint('[Auth] response status: ${e.response?.statusCode}');
    debugPrint('[Auth] error: ${e.error}');
    final status = e.response?.statusCode;
    if (status == 401) return '이메일 또는 비밀번호가 올바르지 않습니다';
    if (status == 409) return '이미 사용 중인 이메일입니다';
    if (status == 422) return '입력 정보를 확인해주세요';
    if (status == 429) return '잠시 후 다시 시도해주세요';
    if (status != null && status >= 500) return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) return '인터넷 연결을 확인해주세요';
    return '알 수 없는 오류가 발생했습니다';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
