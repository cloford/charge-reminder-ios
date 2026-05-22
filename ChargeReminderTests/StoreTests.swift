import XCTest
@testable import ChargeReminder

@MainActor
final class StoreTests: XCTestCase {
    func testSettingsStoreLoadsDefaults() {
        let userDefaults = makeUserDefaults()
        let store = SettingsStore(userDefaults: userDefaults)

        XCTAssertEqual(store.notificationSettings, NotificationSetting.defaultSettings)
        XCTAssertEqual(store.wakeUpSetting, WakeUpSetting.defaultValue)
        XCTAssertEqual(store.lowBatteryThreshold, 50)
        XCTAssertFalse(store.hasCompletedOnboarding)
    }

    func testSettingsStorePersistsUpdates() {
        let userDefaults = makeUserDefaults()
        let store = SettingsStore(userDefaults: userDefaults)
        var updatedNotification = store.notificationSettings[0]
        updatedNotification.hour = 21
        updatedNotification.minute = 15
        updatedNotification.isEnabled = false

        store.updateNotification(updatedNotification)
        store.wakeUpSetting = WakeUpSetting(hour: 6, minute: 30)
        store.lowBatteryThreshold = 60
        store.hasCompletedOnboarding = true

        let reloaded = SettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(reloaded.notificationSettings[0], updatedNotification)
        XCTAssertEqual(reloaded.wakeUpSetting, WakeUpSetting(hour: 6, minute: 30))
        XCTAssertEqual(reloaded.lowBatteryThreshold, 60)
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
    }

    func testScoreStoreMarksAreIdempotent() {
        let store = ScoreStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )

        store.markOpenedAfterNotification()
        store.markOpenedAfterNotification()
        store.markChargingWhenChecked()
        store.markChargingWhenChecked()
        store.markEnoughBatteryInMorning()
        store.markEnoughBatteryInMorning()

        XCTAssertEqual(store.todayScore.total, 3)
        XCTAssertEqual(store.scores.count, 1)
    }

    func testScoreStoreSevenDayAverageUsesMissingDaysAsZero() {
        let userDefaults = makeUserDefaults()
        let store = ScoreStore(
            userDefaults: userDefaults,
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )

        store.markOpenedAfterNotification()
        store.markChargingWhenChecked()

        XCTAssertEqual(store.sevenDayAverage, 2.0 / 7.0, accuracy: 0.001)
    }

    func testScoreStorePersistsWithinInjectedUserDefaultsOnly() {
        let userDefaults = makeUserDefaults()
        let store = ScoreStore(
            userDefaults: userDefaults,
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )

        store.markOpenedAfterNotification()

        let reloaded = ScoreStore(
            userDefaults: userDefaults,
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )
        let isolated = ScoreStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0) },
            calendar: Self.calendar
        )

        XCTAssertEqual(reloaded.todayScore.total, 1)
        XCTAssertEqual(isolated.todayScore.total, 0)
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
