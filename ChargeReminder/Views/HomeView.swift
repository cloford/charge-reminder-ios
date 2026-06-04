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

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: batteryStateIcon)
                            .foregroundStyle(recommendationColor)
                            .frame(width: 24)

                        Text(viewModel.batteryStatus.state.displayName)
                            .font(.headline)

                        Spacer()

                        Text(batteryLevelText)
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
        VStack(spacing: 14) {
            Image(systemName: recommendationIcon)
                .font(.system(size: 44))
                .foregroundStyle(recommendationColor)

            Text(viewModel.recommendation.title)
                .font(.largeTitle.bold())

            Text(viewModel.recommendation.message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("更新 \(viewModel.formattedLastUpdatedAt())")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var batteryLevelText: String {
        guard let level = viewModel.batteryStatus.level else {
            return "不明"
        }
        return "約\(level)%"
    }

    private var recommendationIcon: String {
        switch viewModel.recommendation {
        case .safe:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .chargeRecommended:
            return "bolt.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var recommendationColor: Color {
        switch viewModel.recommendation {
        case .safe:
            return .green
        case .caution:
            return .orange
        case .chargeRecommended:
            return .red
        case .unknown:
            return .secondary
        }
    }

    private var batteryStateIcon: String {
        switch viewModel.batteryStatus.state {
        case .unplugged:
            return "powerplug"
        case .charging:
            return "bolt.fill"
        case .full:
            return "battery.100percent"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private func refreshFromCurrentContext() {
        let source: ChargeCheckSource = NotificationOpenTracker.consumePending() ? .notification : .automatic
        viewModel.refresh(settingsStore: settingsStore, historyStore: historyStore, source: source)
    }
}
