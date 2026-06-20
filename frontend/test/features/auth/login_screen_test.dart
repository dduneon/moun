import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moun/core/network/dio_provider.dart';
import 'package:moun/core/storage/token_storage.dart';
import 'package:moun/features/auth/data/auth_repository.dart';
import 'package:moun/features/auth/domain/auth_model.dart';
import 'package:moun/features/auth/presentation/providers/auth_provider.dart';
import 'package:moun/features/auth/presentation/screens/login_screen.dart';
import 'mock_auth_repository.dart';
import 'mock_token_storage.dart';

Widget buildLogin({
  required MockAuthRepository repo,
  required MockTokenStorage storage,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: const LoginScreen(),
    ),
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
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);
  });

  testWidgets('이메일 필드, 비밀번호 필드, 로그인 버튼이 보인다', (tester) async {
    await tester.pumpWidget(buildLogin(repo: mockRepo, storage: mockStorage));

    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('빈 폼 제출 시 유효성 오류 표시', (tester) async {
    await tester.pumpWidget(buildLogin(repo: mockRepo, storage: mockStorage));

    await tester.tap(find.text('로그인'));
    await tester.pump();

    expect(find.text('올바른 이메일을 입력해주세요'), findsOneWidget);
  });

  testWidgets('잘못된 이메일 형식 → 유효성 오류', (tester) async {
    await tester.pumpWidget(buildLogin(repo: mockRepo, storage: mockStorage));

    await tester.enterText(find.byType(TextFormField).first, 'notanemail');
    await tester.tap(find.text('로그인'));
    await tester.pump();

    expect(find.text('올바른 이메일을 입력해주세요'), findsOneWidget);
  });

  testWidgets('로그인 성공 시 authProvider가 Authenticated로 전환', (tester) async {
    when(() => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => kTokens);
    when(() => mockRepo.getMe()).thenAnswer((_) async => kTestUser);

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: Consumer(builder: (_, ref, __) {
            capturedRef = ref;
            return const LoginScreen();
          }),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass1234');
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(capturedRef.read(authProvider), isA<AuthStateAuthenticated>());
  });

  testWidgets('로그인 실패 시 에러 메시지 표시', (tester) async {
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

    await tester.pumpWidget(buildLogin(repo: mockRepo, storage: mockStorage));

    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong123');
    await tester.tap(find.text('로그인'));
    // pumpAndSettle 대신 pump + 충분한 딜레이
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('이메일 또는 비밀번호'), findsOneWidget);
  });
}
