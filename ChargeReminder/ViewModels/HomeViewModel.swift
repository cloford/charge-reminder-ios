import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var batteryStatus = BatteryStatus(level: nil, state: .unknown)
    @Published private(set) var recommendation: ChargeRecommendation = .unknown

    private let batteryService: BatteryService

    init(batteryService: BatteryService = BatteryService()) {
        self.batteryService = batteryService
    }

    func refresh(settingsStore: SettingsStore, scoreStore: ScoreStore) {
        batteryStatus = batteryService.currentStatus()
        recommendation = BatteryJudgement.recommendation(
            status: batteryStatus,
            wakeUpSetting: settingsStore.wakeUpSetting,
            lowBatteryThreshold: settingsStore.lowBatteryThreshold
        )

        if batteryStatus.state == .charging || batteryStatus.state == .full {
            scoreStore.markChargingWhenChecked()
        }

        if isAfterWakeUp(settingsStore.wakeUpSetting),
           let level = batteryStatus.level,
           level >= settingsStore.lowBatteryThreshold {
            scoreStore.markEnoughBatteryInMorning()
        }
    }

    func nextNotification(from settings: [NotificationSetting]) -> NotificationSetting? {
        let enabled = settings.filter(\.isEnabled)
        return enabled.min { lhs, rhs in
            DateTimeHelper.date(from: lhs.hour, minute: lhs.minute) < DateTimeHelper.date(from: rhs.hour, minute: rhs.minute)
        }
    }

    private func isAfterWakeUp(_ wakeUpSetting: WakeUpSetting) -> Bool {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let wakeMinutes = wakeUpSetting.hour * 60 + wakeUpSetting.minute
        return nowMinutes >= wakeMinutes
    }
}
