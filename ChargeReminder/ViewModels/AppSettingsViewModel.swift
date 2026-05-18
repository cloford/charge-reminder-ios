import Foundation

@MainActor
final class AppSettingsViewModel: ObservableObject {
    @Published private(set) var authorizationStatus: ReminderAuthorizationStatus = .unknown

    func refreshAuthorizationStatus(notificationService: NotificationService) async {
        authorizationStatus = await notificationService.authorizationStatus()
    }
}
