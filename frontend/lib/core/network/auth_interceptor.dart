import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Authorization 헤더 자동 추가 + 401 시 refresh 후 재시도.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    required this.onLogout,
  });

  final TokenStorage tokenStorage;
  final Dio dio;
  final Future<void> Function() onLogout;

  // 여러 요청이 동시에 401을 받아도 refresh는 한 번만 수행하고,
  // 나머지 요청은 그 결과를 기다렸다가 새 토큰으로 재시도한다.
  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // skipAuth: true 인 요청은 토큰 없이 통과 (refresh 요청 등)
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    try {
      final newAccessToken = await (_refreshFuture ??= _refresh());
      if (newAccessToken == null) {
        return handler.next(err);
      }

      // 원래 요청 재시도
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final retryRes = await dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryRes);
    } on DioException {
      // refresh 실패 → 세션 만료로 처리하고 원래 에러 전파
      await onLogout();
      return handler.reject(err);
    }
  }

  Future<String?> _refresh() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await onLogout();
        return null;
      }

      final res = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final newAccessToken = res.data!['access_token'] as String;
      await tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );
      return newAccessToken;
    } finally {
      _refreshFuture = null;
    }
  }
}
