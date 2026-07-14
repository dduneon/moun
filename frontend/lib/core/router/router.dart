import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/fixed_income_screen.dart';
import '../../features/settings/presentation/screens/fixed_expense_screen.dart';
import '../../features/settings/presentation/screens/notification_settings_screen.dart';
import '../../features/settings/presentation/screens/app_info_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/spaces/presentation/screens/space_list_screen.dart';
import '../../features/vouchers/presentation/screens/voucher_screen.dart';
import '../../features/spaces/presentation/screens/invite_preview_screen.dart';
import '../deeplink/deep_link_provider.dart';
import '../widget/home_widget_sync_provider.dart';

/// 앱 최상위 네비게이터 키. main.dart에서 위젯 탭(딥링크)으로 거래 추가
/// 시트를 띄울 때 BuildContext를 얻기 위해 사용한다.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
  // 딥링크 리스너 구독 시작 (콜드/웜 스타트 양쪽 처리)
  ref.read(deepLinkListenerProvider);
  // 홈 화면 위젯에 예산 데이터 동기화 시작
  ref.read(homeWidgetSyncServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _RouterListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState is AuthStateAuthenticated;
      final isAuthenticating = authState is AuthStateAuthenticating;
      final location = state.matchedLocation;

      if (isAuthenticating) return null;

      final onAuthScreen =
          location == '/login' || location == '/register';
      final onOnboarding = location == '/onboarding';
      final onInviteScreen = location.startsWith('/invite/');

      if (!isAuth && !onAuthScreen) return '/login';
      if (authState case AuthStateAuthenticated(:final needsOnboarding)) {
        if (needsOnboarding && !onOnboarding) return '/onboarding';
        if (!needsOnboarding && (onAuthScreen || onOnboarding)) return '/home';

        // 로그인 완료 + 온보딩 불필요 + 대기 중인 초대 링크가 있으면 미리보기로 이동
        final pendingToken = ref.read(pendingInviteTokenProvider);
        if (!needsOnboarding && pendingToken != null && !onInviteScreen) {
          return '/invite/$pendingToken';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) => InvitePreviewScreen(token: state.pathParameters['token']!),
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/statistics', builder: (_, __) => const StatisticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (_, s) => CustomTransitionPage(
                key: s.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // 서브 페이지 진입 시 설정 화면이 살짝 왼쪽으로 밀림
                  final push = Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.25, 0.0),
                  ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic));
                  return SlideTransition(position: push, child: child);
                },
              ),
              routes: [
                GoRoute(path: 'fixed-income', pageBuilder: (_, s) => _settingsPage(const FixedIncomeScreen(), s.pageKey)),
                GoRoute(path: 'fixed-expense', pageBuilder: (_, s) => _settingsPage(const FixedExpenseScreen(), s.pageKey)),
                GoRoute(path: 'vouchers', pageBuilder: (_, s) => _settingsPage(const VoucherScreen(), s.pageKey)),
                GoRoute(path: 'notifications', pageBuilder: (_, s) => _settingsPage(const NotificationSettingsScreen(), s.pageKey)),
                GoRoute(path: 'app-info', pageBuilder: (_, s) => _settingsPage(const AppInfoScreen(), s.pageKey)),
                GoRoute(path: 'spaces', pageBuilder: (_, s) => _settingsPage(const SpaceListScreen(), s.pageKey)),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});


// CupertinoPage를 사용하면 플랫폼에 상관없이 iOS 스타일 왼쪽 엣지 스와이프
// 뒤로가기 제스처가 기본으로 활성화된다.
Page<void> _settingsPage(Widget child, LocalKey key) {
  return CupertinoPage<void>(key: key, child: child);
}

class _RouterListenable extends ChangeNotifier {
  _RouterListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(pendingInviteTokenProvider, (_, __) => notifyListeners());
  }
}
