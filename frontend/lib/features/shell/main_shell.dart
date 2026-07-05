import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/glass_floating_navbar.dart';
import '../../shared/widgets/gradient_background.dart';
import '../home/presentation/providers/selected_calendar_date_provider.dart';
import '../transactions/presentation/widgets/add_transaction_sheet.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    NavBarItem(icon: Icons.home_rounded, label: '홈'),
    NavBarItem(icon: Icons.receipt_long_rounded, label: '거래'),
    NavBarItem(icon: Icons.add_rounded, label: '추가', isCenter: true),
    NavBarItem(icon: Icons.bar_chart_rounded, label: '통계'),
    NavBarItem(icon: Icons.settings_rounded, label: '설정'),
  ];

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 2) {
      // 홈 탭에서 달력 날짜를 선택한 상태라면 해당 날짜를 초기값으로 사용
      final isHomeTab = navigationShell.currentIndex == 0;
      final selectedDate =
          isHomeTab ? ref.read(selectedCalendarDateProvider) : null;
      AddTransactionSheet.show(context, initialDate: selectedDate);
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
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: GlassFloatingNavbar(
          items: _items,
          currentIndex: _navIndex,
          onTap: (i) => _onTap(context, ref, i),
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
