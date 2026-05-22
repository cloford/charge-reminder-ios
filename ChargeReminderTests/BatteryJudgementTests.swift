import XCTest
@testable import ChargeReminder

final class BatteryJudgementTests: XCTestCase {
    private let wakeUpSetting = WakeUpSetting(hour: 7, minute: 0)

    func testUnknownWhenBatteryLevelIsUnavailable() {
        let result = BatteryJudgement.recommendation(
            status: BatteryStatus(level: nil, state: .unplugged),
            wakeUpSetting: wakeUpSetting,
            lowBatteryThreshold: 50
        )

        XCTAssertEqual(result, .unknown)
    }

    func testSafeWhenChargingOrFull() {
        XCTAssertEqual(
            BatteryJudgement.recommendation(
                status: BatteryStatus(level: 20, state: .charging),
                wakeUpSetting: wakeUpSetting,
                lowBatteryThreshold: 50
            ),
            .safe
        )

        XCTAssertEqual(
            BatteryJudgement.recommendation(
                status: BatteryStatus(level: 100, state: .full),
                wakeUpSetting: wakeUpSetting,
                lowBatteryThreshold: 50
            ),
            .safe
        )
    }

    func testSafeWhenUnpluggedAndAtLeastEightyPercent() {
        let result = BatteryJudgement.recommendation(
            status: BatteryStatus(level: 80, state: .unplugged),
            wakeUpSetting: wakeUpSetting,
            lowBatteryThreshold: 50
        )

        XCTAssertEqual(result, .safe)
    }

    func testChargeRecommendedWhenBelowThreshold() {
        let result = BatteryJudgement.recommendation(
            status: BatteryStatus(level: 49, state: .unplugged),
            wakeUpSetting: wakeUpSetting,
            lowBatteryThreshold: 50
        )

        XCTAssertEqual(result, .chargeRecommended)
    }

    func testChargeRecommendedWhenWakeUpIsAtLeastEightHoursAwayAndBelowSixtyPercent() {
        let result = BatteryJudgement.recommendation(
            status: BatteryStatus(level: 59, state: .unplugged),
            wakeUpSetting: wakeUpSetting,
            lowBatteryThreshold: 50,
            now: makeDate(year: 2026, month: 5, day: 22, hour: 22, minute: 30),
            calendar: Self.calendar
        )

        XCTAssertEqual(result, .chargeRecommended)
    }

    func testCautionWhenBetweenThresholdAndSafeRange() {
        let result = BatteryJudgement.recommendation(
            status: BatteryStatus(level: 60, state: .unplugged),
            wakeUpSetting: wakeUpSetting,
            lowBatteryThreshold: 50,
            now: makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 30),
            calendar: Self.calendar
        )

        XCTAssertEqual(result, .caution)
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: Self.calendar,
            timeZone: Self.calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
