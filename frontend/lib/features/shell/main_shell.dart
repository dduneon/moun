import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/glass_floating_navbar.dart';
import '../../shared/widgets/gradient_background.dart';
import '../transactions/presentation/widgets/add_transaction_sheet.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    NavBarItem(icon: Icons.home_rounded, label: '홈'),
    NavBarItem(icon: Icons.receipt_long_rounded, label: '거래'),
    NavBarItem(icon: Icons.add_rounded, label: '추가', isCenter: true),
    NavBarItem(icon: Icons.bar_chart_rounded, label: '통계'),
    NavBarItem(icon: Icons.settings_rounded, label: '설정'),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      AddTransactionSheet.show(context);
      return;
    }
    // + 버튼이 index 2이므로 실제 브랜치 인덱스 조정
    final branch = index < 2 ? index : index - 1;
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: GlassFloatingNavbar(
          items: _items,
          currentIndex: _navIndex,
          onTap: (i) => _onTap(context, i),
        ),
      ),
    );
  }

  // 브랜치 인덱스(0~3) → 탭 인덱스(0,1,3,4)로 변환
  int get _navIndex {
    final branch = navigationShell.currentIndex;
    return branch < 2 ? branch : branch + 1;
  }
}
