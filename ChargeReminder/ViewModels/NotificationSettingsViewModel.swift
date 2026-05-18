import Foundation

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    func requestAuthorization(notificationService: NotificationService) async -> Bool {
        await notificationService.requestAuthorization()
    }

    func reschedule(settings: [NotificationSetting], notificationService: NotificationService) async {
        await notificationService.rescheduleNotifications(settings: settings)
    }
}
