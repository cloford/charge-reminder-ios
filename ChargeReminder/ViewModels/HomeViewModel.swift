import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var batteryStatus = BatteryStatus(level: nil, state: .unknown)
    @Published private(set) var recommendation: ChargeRecommendation = .unknown
    @Published private(set) var lastUpdatedAt: Date?

    private let batteryService: BatteryServiceProtocol
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        batteryService: BatteryServiceProtocol = BatteryService(),
        nowProvider: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.batteryService = batteryService
        self.nowProvider = nowProvider
        self.calendar = calendar
    }

    func refresh(
        settingsStore: SettingsStore,
        historyStore: HistoryStore,
        source: ChargeCheckSource = .automatic
    ) {
        batteryStatus = batteryService.currentStatus()
        lastUpdatedAt = nowProvider()
        recommendation = BatteryJudgement.recommendation(
            status: batteryStatus,
            wakeUpSetting: settingsStore.wakeUpSetting,
            lowBatteryThreshold: settingsStore.lowBatteryThreshold,
            now: nowProvider(),
            calendar: calendar
        )
        historyStore.recordCheck(status: batteryStatus, source: source)
    }

    func nextNotification(from settings: [NotificationSetting]) -> NotificationSetting? {
        let enabled = settings.filter(\.isEnabled)
        return enabled.min { lhs, rhs in
            DateTimeHelper.date(from: lhs.hour, minute: lhs.minute, relativeTo: nowProvider(), calendar: calendar) < DateTimeHelper.date(from: rhs.hour, minute: rhs.minute, relativeTo: nowProvider(), calendar: calendar)
        }
    }

    func formattedLastUpdatedAt() -> String {
        guard let lastUpdatedAt else {
            return "未更新"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: lastUpdatedAt)
    }

}
