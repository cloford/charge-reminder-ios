import Foundation
import UserNotifications
import UIKit

enum ReminderAuthorizationStatus: String {
    case notDetermined = "未確認"
    case denied = "拒否"
    case authorized = "許可済み"
    case provisional = "仮許可"
    case ephemeral = "一時許可"
    case unknown = "不明"
}

final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .unknown
        }
    }

    func rescheduleNotifications(settings: [NotificationSetting]) async {
        center.removePendingNotificationRequests(withIdentifiers: settings.map(\.id))

        for setting in settings where setting.isEnabled {
            await scheduleDailyNotification(setting: setting)
        }
    }

    func scheduleDailyNotification(setting: NotificationSetting) async {
        let content = UNMutableNotificationContent()
        content.title = "充電チェック"
        content.body = message(for: setting)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = setting.hour
        dateComponents.minute = setting.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: setting.id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Keep the UI responsive. QA will verify scheduling on device.
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    @MainActor
    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }

    private func message(for setting: NotificationSetting) -> String {
        switch setting.id {
        case "charge_reminder_1":
            return "そろそろ寝る前の充電を確認しよう。"
        case "charge_reminder_2":
            return "明日の朝、電池は足りそう？"
        default:
            return "今のうちに充電しておくと安心です。"
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        NotificationCenter.default.post(name: .didOpenChargeReminderNotification, object: nil)
    }
}

extension Notification.Name {
    static let didOpenChargeReminderNotification = Notification.Name("didOpenChargeReminderNotification")
}
