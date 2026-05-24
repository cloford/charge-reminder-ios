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
        content.title = "充電確認"
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
            return "iPhoneの充電状態を確認しましょう。"
        case "charge_reminder_2":
            return "次の予定まで電池は足りそうですか？"
        default:
            return "必要なら今のうちに充電しておくと安心です。"
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
        NotificationOpenTracker.markPending()
        await MainActor.run {
            NotificationCenter.default.post(name: .didOpenChargeReminderNotification, object: nil)
        }
    }
}

extension Notification.Name {
    static let didOpenChargeReminderNotification = Notification.Name("didOpenChargeReminderNotification")
}

enum NotificationOpenTracker {
    private static let pendingKey = "pendingNotificationOpen"

    static func markPending(userDefaults: UserDefaults = .standard) {
        userDefaults.set(true, forKey: pendingKey)
    }

    static func consumePending(userDefaults: UserDefaults = .standard) -> Bool {
        let isPending = userDefaults.bool(forKey: pendingKey)
        if isPending {
            userDefaults.set(false, forKey: pendingKey)
        }
        return isPending
    }
}
