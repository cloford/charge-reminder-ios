import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var scoreStore: ScoreStore
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

                Section("今日の習慣メモ") {
                    LabeledContent("達成", value: "\(scoreStore.todayScore.total) / 3")
                    Text("競うものではなく、夜の充電確認ができたかを見る目安です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("充電確認")
            .toolbar {
                Button {
                    viewModel.refresh(settingsStore: settingsStore, scoreStore: scoreStore)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("状態を更新")
            }
            .refreshable {
                viewModel.refresh(settingsStore: settingsStore, scoreStore: scoreStore)
            }
            .onAppear {
                viewModel.refresh(settingsStore: settingsStore, scoreStore: scoreStore)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refresh(settingsStore: settingsStore, scoreStore: scoreStore)
                }
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
}
