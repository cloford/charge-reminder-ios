import SwiftUI

@main
struct ChargeReminderApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settingsStore)
                .environmentObject(historyStore)
                .environmentObject(notificationService)
        }
    }
}
