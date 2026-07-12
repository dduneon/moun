import WidgetKit

private let appGroupId = "group.com.dduneon.moun"

struct BudgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        // Flutter가 예산 데이터를 저장할 때마다 HomeWidget.updateWidget()으로 즉시
        // 리로드를 요청하므로, 여기서는 다음 리프레시를 별도로 예약하지 않는다.
        completion(Timeline(entries: [loadEntry()], policy: .never))
    }

    private func loadEntry() -> BudgetEntry {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let label = defaults.string(forKey: "label"),
            let available = defaults.string(forKey: "available").flatMap(Double.init),
            let expectedIncome = defaults.string(forKey: "expectedIncome").flatMap(Double.init),
            let variableExpense = defaults.string(forKey: "variableExpense").flatMap(Double.init),
            let totalFixedExpense = defaults.string(forKey: "totalFixedExpense").flatMap(Double.init)
        else {
            return .placeholder
        }
        return BudgetEntry(
            date: Date(),
            hasData: true,
            label: label,
            available: available,
            expectedIncome: expectedIncome,
            variableExpense: variableExpense,
            totalFixedExpense: totalFixedExpense
        )
    }
}
