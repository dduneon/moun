import SwiftUI

struct MediumBudgetView: View {
    let entry: BudgetEntry

    private var ratio: Double {
        guard entry.expectedIncome > 0 else { return 0 }
        let spent = entry.variableExpense + entry.totalFixedExpense
        return min(max(spent / entry.expectedIncome, 0), 1)
    }

    private var progressColor: Color {
        ratio > 0.85 ? .red : (ratio > 0.65 ? .orange : .accentColor)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("이번 달 남은 금액")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.hasData {
                    Text(WonFormatter.format(entry.available))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if !entry.label.isEmpty {
                        Text(entry.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: ratio)
                        .tint(progressColor)
                } else {
                    Text("데이터 없음")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
                Text("지출 추가")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
