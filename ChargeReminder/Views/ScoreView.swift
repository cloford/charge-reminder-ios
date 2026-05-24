import SwiftUI

struct ScoreView: View {
    @EnvironmentObject private var scoreStore: ScoreStore
    @StateObject private var viewModel = ScoreViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("今日", value: "\(scoreStore.todayScore.total) / 3")
                    LabeledContent("直近7日平均", value: String(format: "%.1f / 3", scoreStore.sevenDayAverage))
                    Text(viewModel.scoreComment(for: scoreStore.todayScore))
                        .foregroundStyle(.secondary)
                }

                Section("内訳") {
                    ScoreCheckRow(title: "夜の通知後に確認した", isDone: scoreStore.todayScore.openedAfterNotification)
                    ScoreCheckRow(title: "夜の確認時に充電中だった", isDone: scoreStore.todayScore.wasChargingWhenChecked)
                    ScoreCheckRow(title: "翌朝バッテリーが十分だった", isDone: scoreStore.todayScore.hadEnoughBatteryInMorning)
                }

                Section {
                    Text("18:00〜3:59の確認を対象にします。昼間のテスト通知で稼ぐためのものではなく、夜の充電習慣を見るための目安です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("習慣メモ")
        }
    }
}

private struct ScoreCheckRow: View {
    var title: String
    var isDone: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .secondary)
        }
    }
}
