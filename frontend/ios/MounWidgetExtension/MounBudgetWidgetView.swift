import SwiftUI
import WidgetKit

struct MounBudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BudgetEntry

    var body: some View {
        content
            // 위젯 전체를 탭하면 앱이 열리며 거래 추가 화면으로 이동한다.
            // (기존 app_links 기반 딥링크 파이프라인이 그대로 처리)
            .widgetURL(URL(string: "moun://add-transaction"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:
            MediumBudgetView(entry: entry)
        default:
            SmallBudgetView(entry: entry)
        }
    }
}
