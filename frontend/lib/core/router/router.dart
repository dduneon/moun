import 'package:flutter/material.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  Future.microtask(() => ref.read(authProvider.notifier).restoreSession());

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState is AuthStateAuthenticated;
      final isAuthenticating = authState is AuthStateAuthenticating;
      final location = state.matchedLocation;

      if (isAuthenticating) return null;

      final onAuthScreen =
          location == '/login' || location == '/register';
      final onOnboarding = location == '/onboarding';

      if (!isAuth && !onAuthScreen) return '/login';
      if (authState case AuthStateAuthenticated(:final needsOnboarding)) {
        if (needsOnboarding && !onOnboarding) return '/onboarding';
        if (!needsOnboarding && (onAuthScreen || onOnboarding)) return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

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
                GoRoute(path: 'notifications', pageBuilder: (_, s) => _settingsPage(const NotificationSettingsScreen(), s.pageKey)),
                GoRoute(path: 'app-info', pageBuilder: (_, s) => _settingsPage(const AppInfoScreen(), s.pageKey)),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});


CustomTransitionPage<void> _settingsPage(Widget child, LocalKey key) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
