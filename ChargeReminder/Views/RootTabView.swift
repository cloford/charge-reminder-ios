import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var scoreStore: ScoreStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            NotificationSettingsView()
                .tabItem {
                    Label("通知", systemImage: "bell")
                }

            ScoreView()
                .tabItem {
                    Label("スコア", systemImage: "chart.bar")
                }

            AppSettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didOpenChargeReminderNotification)) { _ in
            scoreStore.markOpenedAfterNotification()
        }
    }
}
