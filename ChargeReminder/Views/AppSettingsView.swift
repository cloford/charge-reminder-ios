import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var notificationService: NotificationService
    @StateObject private var viewModel = AppSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("起床時刻") {
                    DatePicker(
                        "起床予定",
                        selection: wakeUpBinding,
                        displayedComponents: .hourAndMinute
                    )
                }

                Section("バッテリー") {
                    Stepper(
                        "しきい値 \(settingsStore.lowBatteryThreshold)%",
                        value: $settingsStore.lowBatteryThreshold,
                        in: 10...90,
                        step: 5
                    )
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

    private var wakeUpBinding: Binding<Date> {
        Binding {
            DateTimeHelper.date(
                from: settingsStore.wakeUpSetting.hour,
                minute: settingsStore.wakeUpSetting.minute
            )
        } set: { newDate in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
            settingsStore.wakeUpSetting = WakeUpSetting(
                hour: components.hour ?? settingsStore.wakeUpSetting.hour,
                minute: components.minute ?? settingsStore.wakeUpSetting.minute
            )
        }
    }
}
