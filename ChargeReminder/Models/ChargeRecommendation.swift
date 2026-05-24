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
            return "次の予定まで大きな心配はなさそうです。"
        case .caution:
            return "残量に少し余裕がありません。外出前や休む前に充電を確認しましょう。"
        case .chargeRecommended:
            return "このままだと不足する可能性があります。今のうちに充電しておくと安心です。"
        case .unknown:
            return "バッテリー状態を取得できませんでした。"
        }
    }
}
