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
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.recommendation.title)
                            .font(.title2.bold())
                        Text(viewModel.recommendation.message)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("バッテリー") {
                    LabeledContent("残量", value: batteryLevelText)
                    LabeledContent("状態", value: viewModel.batteryStatus.state.displayName)
                }

                Section("予定") {
                    LabeledContent("起床予定", value: settingsStore.wakeUpSetting.displayTime)
                    LabeledContent("次回通知", value: nextNotificationText)
                }

                Section("今日のスコア") {
                    LabeledContent("スコア", value: "\(scoreStore.todayScore.total) / 3")
                }

                Button {
                    viewModel.refresh(settingsStore: settingsStore, scoreStore: scoreStore)
                } label: {
                    Label("状態を更新", systemImage: "arrow.clockwise")
                }
            }
            .navigationTitle("充電チェック")
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

    private var batteryLevelText: String {
        guard let level = viewModel.batteryStatus.level else {
            return "不明"
        }
        return "\(level)%"
    }

    private var nextNotificationText: String {
        viewModel.nextNotification(from: settingsStore.notificationSettings)?.displayTime ?? "なし"
    }
}
