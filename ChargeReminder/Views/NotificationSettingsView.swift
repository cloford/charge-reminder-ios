import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @State private var isShowingInformation = false

    var body: some View {
        NavigationStack {
            List {
                Section("起床予定") {
                    DatePicker(
                        "",
                        selection: wakeUpBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("起床予定")
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

                if viewModel.authorizationStatus == .notDetermined {
                    Section {
                        Button {
                            Task {
                                _ = await viewModel.requestAuthorization(notificationService: notificationService)
                                await viewModel.reschedule(
                                    settings: settingsStore.notificationSettings,
                                    notificationService: notificationService
                                )
                            }
                        } label: {
                            Label("通知を許可", systemImage: "bell.badge")
                        }
                    }
                } else if viewModel.authorizationStatus == .denied {
                    Section {
                        Button {
                            notificationService.openSystemNotificationSettings()
                        } label: {
                            Label("iOS設定で通知を許可", systemImage: "gear")
                        }
                    } footer: {
                        Text("通知が拒否されているため、設定した時刻に通知されません。")
                    }
                }
            }
            .navigationTitle("予定")
            .toolbar {
                Button {
                    isShowingInformation = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("予定について")
            }
            .sheet(isPresented: $isShowingInformation) {
                ScheduleInformationView()
            }
            .task {
                await viewModel.refreshAuthorizationStatus(notificationService: notificationService)
                await viewModel.reschedule(
                    settings: settingsStore.notificationSettings,
                    notificationService: notificationService
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }
                Task {
                    await viewModel.refreshAuthorizationStatus(notificationService: notificationService)
                }
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
        HStack {
            DatePicker(
                "",
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
            .labelsHidden()
            .accessibilityLabel("通知時刻")

            Spacer()

            Toggle("", isOn: Binding(
                get: { setting.isEnabled },
                set: { isEnabled in
                    var updated = setting
                    updated.isEnabled = isEnabled
                    onChange(updated)
                }
            ))
            .labelsHidden()
            .accessibilityLabel("\(setting.displayTime)の通知")
        }
        .onChange(of: setting) { _, newSetting in
            selectedDate = DateTimeHelper.date(from: newSetting.hour, minute: newSetting.minute)
        }
    }
}

private struct ScheduleInformationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("起床予定") {
                    Text("次の予定までバッテリーが持ちそうかを判断するために使います。")
                }

                Section("通知") {
                    Text("設定した時刻に、充電状態の確認を促すリマインダーを表示します。")
                    Text("通知はiOSの通知設定や集中モードの影響を受けます。")
                }
            }
            .navigationTitle("予定について")
            .toolbar {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}
