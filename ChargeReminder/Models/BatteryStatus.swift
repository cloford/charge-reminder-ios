import Foundation

struct BatteryStatus: Equatable {
    var level: Int?
    var state: BatteryConnectionState
}

enum BatteryConnectionState: String, Equatable {
    case unplugged
    case charging
    case full
    case unknown

    var displayName: String {
        switch self {
        case .unplugged:
            return "未接続"
        case .charging:
            return "充電中"
        case .full:
            return "充電完了"
        case .unknown:
            return "不明"
        }
    }
}
