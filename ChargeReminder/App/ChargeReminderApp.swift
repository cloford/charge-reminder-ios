import SwiftUI

@main
struct ChargeReminderApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var scoreStore = ScoreStore()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settingsStore)
                .environmentObject(scoreStore)
                .environmentObject(notificationService)
        }
    }
}
