import Foundation

@MainActor
final class ScoreViewModel: ObservableObject {
    func scoreComment(for score: ChargeScore) -> String {
        switch score.total {
        case 3:
            return "良い充電習慣です。"
        case 2:
            return "かなり良いです。あと少し安定させましょう。"
        case 1:
            return "寝る前の確認を少し増やしましょう。"
        default:
            return "まずは通知後に確認するところから始めましょう。"
        }
    }
}
