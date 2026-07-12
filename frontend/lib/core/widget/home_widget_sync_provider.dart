import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/budget/domain/budget_models.dart';
import '../../features/budget/presentation/providers/budget_provider.dart';

const _appGroupId = 'group.com.dduneon.moun';
const _widgetKind = 'MounBudgetWidget';

/// 이번 사이클 가용 예산이 갱신될 때마다 iOS 홈 화면 위젯(App Group
/// UserDefaults)에 값을 반영한다. availableBudgetProvider는 거래 추가/수정/
/// 삭제 시 이미 invalidate되므로 별도 트리거 없이 이 리스너만으로 충분하다.
class HomeWidgetSyncService {
  HomeWidgetSyncService(this._ref) {
    HomeWidget.setAppGroupId(_appGroupId);
    _ref.listen<AsyncValue<AvailableBudget>>(
      availableBudgetProvider,
      (_, next) => next.whenData(_sync),
      fireImmediately: true,
    );
  }

  final Ref _ref;

  Future<void> _sync(AvailableBudget budget) async {
    await HomeWidget.saveWidgetData<String>('available', budget.available.toString());
    await HomeWidget.saveWidgetData<String>('expectedIncome', budget.expectedIncome.toString());
    await HomeWidget.saveWidgetData<String>('variableExpense', budget.variableExpense.toString());
    await HomeWidget.saveWidgetData<String>('totalFixedExpense', budget.totalFixedExpense.toString());
    await HomeWidget.saveWidgetData<String>('label', budget.label);
    await HomeWidget.updateWidget(iOSName: _widgetKind);
  }
}

final homeWidgetSyncServiceProvider = Provider<HomeWidgetSyncService>((ref) {
  return HomeWidgetSyncService(ref);
});
