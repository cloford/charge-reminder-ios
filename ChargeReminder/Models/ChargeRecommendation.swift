import Foundation

enum ChargeRecommendation: Equatable {
    case safe
    case caution
    case chargeRecommended
    case unknown

    var title: String {
        switch self {
        case .safe:
            return "安全"
        case .caution:
            return "注意"
        case .chargeRecommended:
            return "充電推奨"
        case .unknown:
            return "状態不明"
        }
    }

    var message: String {
        switch self {
        case .safe:
            return "今のところ余裕があります。"
        case .caution:
            return "寝る前に充電を確認しておくと安心です。"
        case .chargeRecommended:
            return "朝まで不安があります。今のうちに充電しましょう。"
        case .unknown:
            return "バッテリー状態を取得できませんでした。"
        }
    }
}
