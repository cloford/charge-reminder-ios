import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List {
                if historyStore.recentRecords.isEmpty {
                    Text("まだ記録がありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(historyStore.recentRecords) { record in
                        HistoryRecordRow(record: record, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("確認記録")
        }
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

            Text(record.batteryState.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
