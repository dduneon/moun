import SwiftUI
import WidgetKit

struct MounBudgetWidget: Widget {
    let kind: String = "MounBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetTimelineProvider()) { entry in
            MounBudgetWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("이번 달 남은 금액")
        .description("이번 달 남은 예산을 홈 화면에서 바로 확인하고, 탭해서 지출을 추가하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
