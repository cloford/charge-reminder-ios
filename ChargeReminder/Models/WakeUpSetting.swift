import Foundation

struct WakeUpSetting: Codable, Equatable {
    var hour: Int
    var minute: Int

    var displayTime: String {
        String(format: "%02d:%02d", hour, minute)
    }

    static let defaultValue = WakeUpSetting(hour: 7, minute: 0)
}
