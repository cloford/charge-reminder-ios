import XCTest
@testable import ChargeReminder

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testRefreshUsesInjectedBatteryStatusForRecommendation() {
        let viewModel = HomeViewModel(
            batteryService: FakeBatteryService(status: BatteryStatus(level: 49, state: .unplugged)),
            nowProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )
        let settingsStore = SettingsStore(userDefaults: makeUserDefaults())
        let historyStore = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) }
        )

        viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore)

        XCTAssertEqual(viewModel.batteryStatus, BatteryStatus(level: 49, state: .unplugged))
        XCTAssertEqual(viewModel.recommendation, .chargeRecommended)
        XCTAssertEqual(historyStore.latestRecord?.batteryLevel, 49)
    }

    func testRefreshRecordsChargingState() {
        let viewModel = HomeViewModel(
            batteryService: FakeBatteryService(status: BatteryStatus(level: 70, state: .charging)),
            nowProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )
        let settingsStore = SettingsStore(userDefaults: makeUserDefaults())
        let historyStore = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) }
        )

        viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore, source: .manual)

        XCTAssertEqual(historyStore.latestRecord?.batteryState, .charging)
        XCTAssertEqual(historyStore.latestRecord?.source, .manual)
    }

    func testRefreshRecordsMorningBatteryState() {
        let viewModel = HomeViewModel(
            batteryService: FakeBatteryService(status: BatteryStatus(level: 80, state: .unplugged)),
            nowProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 7, minute: 30) },
            calendar: Self.calendar
        )
        let settingsStore = SettingsStore(userDefaults: makeUserDefaults())
        let historyStore = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 7, minute: 30) }
        )

        viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore)

        XCTAssertEqual(historyStore.latestRecord?.batteryLevel, 80)
        XCTAssertEqual(historyStore.latestRecord?.batteryState, .unplugged)
    }

    func testNextNotificationChoosesSoonestEnabledTimeRelativeToNow() {
        let viewModel = HomeViewModel(
            batteryService: FakeBatteryService(status: BatteryStatus(level: 80, state: .unplugged)),
            nowProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 22, minute: 30) },
            calendar: Self.calendar
        )
        let settings = [
            NotificationSetting(id: "disabled", hour: 22, minute: 45, isEnabled: false),
            NotificationSetting(id: "tomorrow", hour: 22, minute: 0, isEnabled: true),
            NotificationSetting(id: "today", hour: 23, minute: 0, isEnabled: true)
        ]

        XCTAssertEqual(viewModel.nextNotification(from: settings)?.id, "today")
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "ChargeReminderTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}

private struct FakeBatteryService: BatteryServiceProtocol {
    var status: BatteryStatus

    func currentStatus() -> BatteryStatus {
        status
    }
}
