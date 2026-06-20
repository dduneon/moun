import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 앱 시작 시 한 번만 세션 복원
  Future.microtask(() => ref.read(authProvider.notifier).restoreSession());

  final authNotifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState is AuthStateAuthenticated;
      final isAuthenticating = authState is AuthStateAuthenticating;
      final location = state.matchedLocation;

      if (isAuthenticating) return null;

      final onAuthScreen = location == '/login' || location == '/register';

      if (!isAuth && !onAuthScreen) return '/login';
      if (isAuth && onAuthScreen) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
        // 추후 중첩 라우트 추가 예정
      ),
    ],
  );
});

/// GoRouter의 refreshListenable용 — authProvider 변화 시 라우터 재평가.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
