import Foundation

enum DateTimeHelper {
    static func date(
        from hour: Int,
        minute: Int,
        relativeTo baseDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let sameDayDate = calendar.date(from: components) else {
            return baseDate
        }

        if sameDayDate < baseDate {
            return calendar.date(byAdding: .day, value: 1, to: sameDayDate) ?? sameDayDate
        }

        return sameDayDate
    }

    static func hoursUntil(
        hour: Int,
        minute: Int,
        from baseDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Double {
        let targetDate = date(from: hour, minute: minute, relativeTo: baseDate, calendar: calendar)
        return targetDate.timeIntervalSince(baseDate) / 3600
    }

    static func dayKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
