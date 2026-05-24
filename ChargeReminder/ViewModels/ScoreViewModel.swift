import Foundation

@MainActor
final class ScoreViewModel: ObservableObject {
    func scoreComment(for score: ChargeScore) -> String {
        switch score.total {
        case 3:
            return "夜の充電確認が安定しています。"
        case 2:
            return "良い流れです。翌朝の確認までできるとさらに安定します。"
        case 1:
            return "まずは夜の通知後に確認する習慣を作りましょう。"
        default:
            return "夜の充電確認から始めましょう。"
        }
    }
}
