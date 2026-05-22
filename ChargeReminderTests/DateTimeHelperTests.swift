import XCTest
@testable import ChargeReminder

final class DateTimeHelperTests: XCTestCase {
    func testDateReturnsSameDayFutureTime() {
        let baseDate = makeDate(year: 2026, month: 5, day: 22, hour: 20, minute: 0)

        let result = DateTimeHelper.date(
            from: 22,
            minute: 30,
            relativeTo: baseDate,
            calendar: Self.calendar
        )

        XCTAssertEqual(result, makeDate(year: 2026, month: 5, day: 22, hour: 22, minute: 30))
    }

    func testDateRollsPastTimeToNextDay() {
        let baseDate = makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0)

        let result = DateTimeHelper.date(
            from: 22,
            minute: 30,
            relativeTo: baseDate,
            calendar: Self.calendar
        )

        XCTAssertEqual(result, makeDate(year: 2026, month: 5, day: 23, hour: 22, minute: 30))
    }

    func testHoursUntilUsesNextMatchingTime() {
        let baseDate = makeDate(year: 2026, month: 5, day: 22, hour: 23, minute: 0)

        let result = DateTimeHelper.hoursUntil(
            hour: 7,
            minute: 0,
            from: baseDate,
            calendar: Self.calendar
        )

        XCTAssertEqual(result, 8.0, accuracy: 0.001)
    }

    func testDayKeyUsesProvidedCalendar() {
        let date = makeDate(year: 2026, month: 5, day: 22, hour: 13, minute: 45)

        XCTAssertEqual(DateTimeHelper.dayKey(for: date, calendar: Self.calendar), "2026-05-22")
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
