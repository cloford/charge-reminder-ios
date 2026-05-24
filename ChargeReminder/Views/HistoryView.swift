import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("最新の確認") {
                    if let latestRecord = historyStore.latestRecord {
                        HistoryRecordDetail(record: latestRecord, viewModel: viewModel)
                    } else {
                        Text("まだ確認履歴がありません。")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("直近の履歴") {
                    if historyStore.recentRecords.isEmpty {
                        Text("ホーム画面で状態を確認すると、ここに履歴が残ります。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(historyStore.recentRecords) { record in
                            HistoryRecordRow(record: record, viewModel: viewModel)
                        }
                    }
                }

                Section {
                    Text("履歴は採点ではありません。いつ確認し、その時の残量と充電状態がどうだったかを振り返るための記録です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("確認履歴")
        }
    }
}

private struct HistoryRecordDetail: View {
    var record: ChargeCheckRecord
    var viewModel: HistoryViewModel

    var body: some View {
        LabeledContent("時刻", value: viewModel.fullDateText(for: record.checkedAt))
        LabeledContent("残量", value: record.batteryLevelText)
        LabeledContent("状態", value: record.batteryState.displayName)
        LabeledContent("きっかけ", value: record.source.displayName)
    }
}

private struct HistoryRecordRow: View {
    var record: ChargeCheckRecord
    var viewModel: HistoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(viewModel.shortDateText(for: record.checkedAt))
                    .font(.headline)
                Spacer()
                Text(record.batteryLevelText)
                    .foregroundStyle(.secondary)
            }

            Text("\(record.batteryState.displayName) / \(record.source.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
