import Foundation

enum WonFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f
    }()

    static func format(_ amount: Double) -> String {
        let rounded = amount.rounded()
        let text = formatter.string(from: NSNumber(value: rounded)) ?? "\(Int(rounded))"
        return "\(text)원"
    }
}
