import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    private let locale = Locale(identifier: "ja_JP")

    func fullDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "M/d H:mm"
        return formatter.string(from: date)
    }

    func shortDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "M/d H:mm"
        return formatter.string(from: date)
    }
}
