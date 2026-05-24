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

    func testHistoryStoreRecordsCheck() {
        let checkedAt = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 0)
        let store = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { checkedAt }
        )

        store.recordCheck(
            status: BatteryStatus(level: 75, state: .charging),
            source: .manual
        )

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.latestRecord?.checkedAt, checkedAt)
        XCTAssertEqual(store.latestRecord?.batteryLevel, 75)
        XCTAssertEqual(store.latestRecord?.batteryState, .charging)
        XCTAssertEqual(store.latestRecord?.source, .manual)
    }

    func testHistoryStorePersistsWithinInjectedUserDefaultsOnly() {
        let userDefaults = makeUserDefaults()
        let store = HistoryStore(
            userDefaults: userDefaults,
            dateProvider: { Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 0) }
        )

        store.recordCheck(
            status: BatteryStatus(level: 75, state: .charging),
            source: .manual
        )

        let reloaded = HistoryStore(userDefaults: userDefaults)
        let isolated = HistoryStore(userDefaults: makeUserDefaults())

        XCTAssertEqual(reloaded.records.count, 1)
        XCTAssertEqual(isolated.records.count, 0)
    }

    func testHistoryStoreKeepsMostRecentRecordsFirst() {
        var currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 0)
        let store = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { currentDate }
        )

        store.recordCheck(status: BatteryStatus(level: 70, state: .unplugged), source: .automatic)
        currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 13, minute: 0)
        store.recordCheck(status: BatteryStatus(level: 80, state: .charging), source: .manual)

        XCTAssertEqual(store.recentRecords.first?.batteryLevel, 80)
        XCTAssertEqual(store.latestRecord?.batteryLevel, 80)
    }

    func testHistoryStoreSkipsDuplicateAutomaticRecordsWithinFiveMinutes() {
        var currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 0)
        let store = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { currentDate }
        )
        let status = BatteryStatus(level: 80, state: .unplugged)

        store.recordCheck(status: status, source: .automatic)
        currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 1)
        store.recordCheck(status: status, source: .automatic)

        XCTAssertEqual(store.records.count, 1)
    }

    func testHistoryStoreKeepsManualRecordsEvenWhenStatusIsSame() {
        var currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 0)
        let store = HistoryStore(
            userDefaults: makeUserDefaults(),
            dateProvider: { currentDate }
        )
        let status = BatteryStatus(level: 80, state: .unplugged)

        store.recordCheck(status: status, source: .manual)
        currentDate = Self.makeDate(year: 2026, month: 5, day: 24, hour: 12, minute: 1)
        store.recordCheck(status: status, source: .manual)

        XCTAssertEqual(store.records.count, 2)
    }

    func testNotificationOpenTrackerConsumesPendingStateOnce() {
        let userDefaults = makeUserDefaults()

        NotificationOpenTracker.markPending(userDefaults: userDefaults)

        XCTAssertTrue(NotificationOpenTracker.consumePending(userDefaults: userDefaults))
        XCTAssertFalse(NotificationOpenTracker.consumePending(userDefaults: userDefaults))
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "ChargeReminderTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private static func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
