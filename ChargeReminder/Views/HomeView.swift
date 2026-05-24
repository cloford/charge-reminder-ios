import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var historyStore: HistoryStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusHeader
                }

                Section("バッテリー") {
                    LabeledContent("残量", value: batteryLevelText)
                    LabeledContent("状態", value: viewModel.batteryStatus.state.displayName)
                    Text("残量はiOSが返す目安です。端末によって5%刻みのように見える場合があります。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("予定") {
                    LabeledContent("起床予定", value: settingsStore.wakeUpSetting.displayTime)
                    LabeledContent("次回通知", value: nextNotificationText)
                }

                Section("最終確認") {
                    if let latestRecord = historyStore.latestRecord {
                        LabeledContent("時刻", value: recordTimeText(latestRecord))
                        LabeledContent("残量", value: latestRecord.batteryLevelText)
                        LabeledContent("状態", value: latestRecord.batteryState.displayName)
                    } else {
                        Text("まだ確認履歴がありません。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("充電確認")
            .toolbar {
                Button {
                    viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore, source: .manual)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("状態を更新")
            }
            .refreshable {
                viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore, source: .manual)
            }
            .onAppear {
                refreshFromCurrentContext()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshFromCurrentContext()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didOpenChargeReminderNotification)) { _ in
                refreshFromCurrentContext()
            }
        }
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.recommendation.title)
                    .font(.title2.bold())
                Spacer()
                Text("更新 \(viewModel.formattedLastUpdatedAt())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(viewModel.recommendation.message)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var batteryLevelText: String {
        guard let level = viewModel.batteryStatus.level else {
            return "不明"
        }
        return "約\(level)%"
    }

    private var nextNotificationText: String {
        viewModel.nextNotification(from: settingsStore.notificationSettings)?.displayTime ?? "なし"
    }

    private func refreshFromCurrentContext() {
        let source: ChargeCheckSource = NotificationOpenTracker.consumePending() ? .notification : .automatic
        viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore, source: source)
    }

    private func recordTimeText(_ record: ChargeCheckRecord) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d H:mm"
        return formatter.string(from: record.checkedAt)
    }
}
