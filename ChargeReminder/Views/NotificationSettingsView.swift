import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var notificationService: NotificationService
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @State private var authorizationMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let authorizationMessage {
                    Section {
                        Text(authorizationMessage)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("起床予定") {
                    DatePicker(
                        "起床時刻",
                        selection: wakeUpBinding,
                        displayedComponents: .hourAndMinute
                    )
                    Text("起床時刻は、朝まで持ちそうかを判断するために使います。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("通知時刻") {
                    ForEach(settingsStore.notificationSettings) { setting in
                        NotificationSettingRow(setting: setting) { updated in
                            settingsStore.updateNotification(updated)
                            Task {
                                await viewModel.reschedule(
                                    settings: settingsStore.notificationSettings,
                                    notificationService: notificationService
                                )
                            }
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            let granted = await viewModel.requestAuthorization(notificationService: notificationService)
                            authorizationMessage = granted ? "通知が許可されました。" : "通知が許可されていません。"
                            await viewModel.reschedule(
                                settings: settingsStore.notificationSettings,
                                notificationService: notificationService
                            )
                        }
                    } label: {
                        Label("通知を許可して予約を更新", systemImage: "bell.badge")
                    }
                }

                Section {
                    Text("通知は充電状態を確認するためのリマインダーです。iOSの通知設定や集中モードの影響を受けます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("予定")
            .task {
                await viewModel.reschedule(
                    settings: settingsStore.notificationSettings,
                    notificationService: notificationService
                )
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

private struct NotificationSettingRow: View {
    var setting: NotificationSetting
    var onChange: (NotificationSetting) -> Void

    @State private var selectedDate: Date

    init(setting: NotificationSetting, onChange: @escaping (NotificationSetting) -> Void) {
        self.setting = setting
        self.onChange = onChange
        _selectedDate = State(initialValue: DateTimeHelper.date(from: setting.hour, minute: setting.minute))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { setting.isEnabled },
                set: { isEnabled in
                    var updated = setting
                    updated.isEnabled = isEnabled
                    onChange(updated)
                }
            )) {
                Text(setting.displayTime)
            }

            DatePicker(
                "時刻",
                selection: Binding(
                    get: { selectedDate },
                    set: { newDate in
                        selectedDate = newDate
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        var updated = setting
                        updated.hour = components.hour ?? setting.hour
                        updated.minute = components.minute ?? setting.minute
                        onChange(updated)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
        }
        .onChange(of: setting) { _, newSetting in
            selectedDate = DateTimeHelper.date(from: newSetting.hour, minute: newSetting.minute)
        }
    }
}
