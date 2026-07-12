import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/constants/app_constants.dart';
import 'core/deeplink/deep_link_provider.dart';
import 'core/network/dio_provider.dart';
import 'core/router/router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/_design_showcase/showcase_screen.dart';
import 'features/transactions/presentation/widgets/add_transaction_sheet.dart';

// Set to false to use the real auth router
const _showDesignShowcase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '5d562dc375f809d620ab936174d3d3d0');
  final keyHash = await KakaoSdk.origin;
  // ignore: avoid_print
  print('[Kakao] key hash: $keyHash');
  await initializeDateFormatting('ko');
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(
          SecureTokenStorage(const FlutterSecureStorage()),
        ),
      ],
      child: const MounApp(),
    ),
  );
}

class MounApp extends ConsumerWidget {
  const MounApp({super.key});

  // 홈 화면 위젯 탭(moun://add-transaction)으로 대기 중인 요청이 있으면
  // 거래 추가 시트를 띄우고 플래그를 다시 내린다. 콜드 스타트(빌드 직후 이미
  // true인 경우)와 웜 스타트(실행 중 탭) 양쪽에서 호출된다.
  void _consumePendingWidgetAction(WidgetRef ref) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    ref.read(pendingWidgetActionProvider.notifier).state = false;
    AddTransactionSheet.show(ctx);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(pendingWidgetActionProvider, (prev, next) {
      if (next) _consumePendingWidgetAction(ref);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(pendingWidgetActionProvider)) {
        _consumePendingWidgetAction(ref);
      }
    });

    // 실제 화면에 적용된 테마 밝기(Theme.of(context).brightness) 기준으로
    // 상태바 아이콘 색을 정한다. MaterialApp 바깥에서 시스템 다크모드 설정만
    // 보고 판단하면, 실제 렌더링된 배경 색과 어긋나 흰 배경에 흰 아이콘이
    // 겹치는 문제가 생길 수 있다.
    Widget statusBarStyleBuilder(BuildContext context, Widget? child) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final overlayStyle = isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            );
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: child!,
      );
    }

    if (_showDesignShowcase) {
      return MaterialApp(
        title: appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const DesignShowcaseScreen(),
        debugShowCheckedModeBanner: false,
        builder: statusBarStyleBuilder,
      );
    }

    return MaterialApp.router(
      title: appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      builder: statusBarStyleBuilder,
    );
  }
}
