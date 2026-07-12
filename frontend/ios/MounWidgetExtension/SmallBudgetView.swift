import SwiftUI

struct SmallBudgetView: View {
    let entry: BudgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("이번 달 남은 금액")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            if entry.hasData {
                Text(WonFormatter.format(entry.available))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Text("데이터 없음")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                Text("지출 추가")
                    .font(.caption2)
            }
            .foregroundStyle(Color.accentColor)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
