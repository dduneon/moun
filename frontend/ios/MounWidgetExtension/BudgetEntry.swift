import WidgetKit

struct BudgetEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let label: String
    let available: Double
    let expectedIncome: Double
    let variableExpense: Double
    let totalFixedExpense: Double

    static let placeholder = BudgetEntry(
        date: Date(),
        hasData: false,
        label: "",
        available: 0,
        expectedIncome: 0,
        variableExpense: 0,
        totalFixedExpense: 0
    )
}
