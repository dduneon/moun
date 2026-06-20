import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden');
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final storage = ref.read(tokenStorageProvider);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: storage,
      dio: dio,
      onLogout: () async {
        await storage.clearTokens();
        // authNotifierProvider를 직접 참조하면 순환 의존이 생기므로
        // clearTokens만 하고 router가 상태 변화를 감지해 리다이렉트
      },
    ),
  );

  return dio;
});
