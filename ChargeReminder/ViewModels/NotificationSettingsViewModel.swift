import Foundation

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var authorizationStatus: ReminderAuthorizationStatus = .unknown

    func requestAuthorization(notificationService: NotificationService) async -> Bool {
        let granted = await notificationService.requestAuthorization()
        await refreshAuthorizationStatus(notificationService: notificationService)
        return granted
    }

    func refreshAuthorizationStatus(notificationService: NotificationService) async {
        authorizationStatus = await notificationService.authorizationStatus()
    }

    func reschedule(settings: [NotificationSetting], notificationService: NotificationService) async {
        await notificationService.rescheduleNotifications(settings: settings)
    }
}
