import Foundation

struct ChargeScore: Codable, Identifiable, Equatable {
    var id: String { dayKey }
    var dayKey: String
    var openedAfterNotification: Bool
    var wasChargingWhenChecked: Bool
    var hadEnoughBatteryInMorning: Bool

    var total: Int {
        [openedAfterNotification, wasChargingWhenChecked, hadEnoughBatteryInMorning].filter { $0 }.count
    }

    static func empty(dayKey: String) -> ChargeScore {
        ChargeScore(
            dayKey: dayKey,
            openedAfterNotification: false,
            wasChargingWhenChecked: false,
            hadEnoughBatteryInMorning: false
        )
    }
}
