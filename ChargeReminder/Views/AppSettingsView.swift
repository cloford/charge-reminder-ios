import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var notificationService: NotificationService
    @StateObject private var viewModel = AppSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("バッテリー") {
                    Stepper(
                        "充電推奨ライン \(settingsStore.lowBatteryThreshold)%",
                        value: $settingsStore.lowBatteryThreshold,
                        in: 10...90,
                        step: 5
                    )
                    Text("この残量を下回ると、ホーム画面で充電をおすすめします。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("通知") {
                    LabeledContent("状態", value: viewModel.authorizationStatus.rawValue)
                    Button {
                        notificationService.openSystemNotificationSettings()
                    } label: {
                        Label("iOS設定を開く", systemImage: "gear")
                    }
                }

                Section("このアプリについて") {
                    Text("このアプリは充電忘れ防止リマインダーです。目覚ましアラームではありません。")
                    Text("通知はiOSの通知設定に依存します。バックグラウンドで常時バッテリー監視はしません。")
                    Text("バッテリー状態はアプリ起動時・復帰時に確認します。")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("設定")
            .task {
                await viewModel.refreshAuthorizationStatus(notificationService: notificationService)
            }
        }
    }
}
