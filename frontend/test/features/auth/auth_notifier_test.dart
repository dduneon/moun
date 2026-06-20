import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moun/core/network/dio_provider.dart';
import 'package:moun/core/storage/token_storage.dart';
import 'package:moun/features/auth/data/auth_repository.dart';
import 'package:moun/features/auth/domain/auth_model.dart';
import 'package:moun/features/auth/presentation/providers/auth_provider.dart';
import 'mock_auth_repository.dart';
import 'mock_token_storage.dart';

ProviderContainer makeContainer({
  required AuthRepository repo,
  required TokenStorage storage,
}) {
  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockAuthRepository mockRepo;
  late MockTokenStorage mockStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockTokenStorage();

    when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => mockStorage.clearTokens()).thenAnswer((_) async {});
  });

  group('AuthNotifier - restoreSession', () {
    test('저장된 토큰 없으면 Unauthenticated', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).restoreSession();

      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('토큰 있고 /me 성공하면 Authenticated', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'token');
      when(() => mockRepo.getMe()).thenAnswer((_) async => kTestUser);

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).restoreSession();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect((state as AuthStateAuthenticated).user.email, 'test@example.com');
    });

    test('/me 실패 시 토큰 삭제 후 Unauthenticated', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'expired');
      when(() => mockRepo.getMe()).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).restoreSession();

      verify(() => mockStorage.clearTokens()).called(1);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });
  });

  group('AuthNotifier - login', () {
    test('로그인 성공 → 토큰 저장 + Authenticated', () async {
      when(() => mockRepo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => kTokens);
      when(() => mockRepo.getMe()).thenAnswer((_) async => kTestUser);

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).login(
            email: 'test@example.com',
            password: 'pass1234',
          );

      verify(() => mockStorage.saveTokens(
            accessToken: 'access_abc',
            refreshToken: 'refresh_xyz',
          )).called(1);
      expect(container.read(authProvider), isA<AuthStateAuthenticated>());
    });

    test('401 응답 → 에러 메시지 throw + Unauthenticated', () async {
      when(() => mockRepo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
        ),
      );

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      expect(
        () => container.read(authProvider.notifier).login(
              email: 'x@x.com',
              password: 'wrong',
            ),
        throwsA(contains('이메일 또는 비밀번호')),
      );
      await Future.delayed(Duration.zero); // state settle
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('409 응답 → 이메일 중복 메시지 throw', () async {
      when(() => mockRepo.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 409,
          ),
        ),
      );

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      expect(
        () => container.read(authProvider.notifier).register(
              email: 'dup@x.com',
              password: 'pass',
              name: '테스터',
            ),
        throwsA(contains('이미 사용 중인 이메일')),
      );
    });
  });

  group('AuthNotifier - logout', () {
    test('로그아웃 → 토큰 삭제 + Unauthenticated', () async {
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_xyz');
      when(() => mockRepo.logout(any())).thenAnswer((_) async {});

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).logout();

      verify(() => mockStorage.clearTokens()).called(1);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('서버 logout 실패해도 로컬 토큰은 삭제', () async {
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_xyz');
      when(() => mockRepo.logout(any())).thenThrow(Exception('network error'));

      final container = makeContainer(repo: mockRepo, storage: mockStorage);
      await container.read(authProvider.notifier).logout();

      verify(() => mockStorage.clearTokens()).called(1);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });
  });
}
