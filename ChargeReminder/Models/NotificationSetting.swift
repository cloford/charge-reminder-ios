import Foundation

struct NotificationSetting: Identifiable, Codable, Equatable {
    let id: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    var displayTime: String {
        String(format: "%02d:%02d", hour, minute)
    }

    static let defaultSettings: [NotificationSetting] = [
        NotificationSetting(id: "charge_reminder_1", hour: 22, minute: 0, isEnabled: true),
        NotificationSetting(id: "charge_reminder_2", hour: 23, minute: 0, isEnabled: true),
        NotificationSetting(id: "charge_reminder_3", hour: 0, minute: 0, isEnabled: true)
    ]
}
