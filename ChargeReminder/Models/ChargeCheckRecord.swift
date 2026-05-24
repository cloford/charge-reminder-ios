import Foundation

struct ChargeCheckRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var checkedAt: Date
    var batteryLevel: Int?
    var batteryState: BatteryConnectionState
    var source: ChargeCheckSource

    var batteryLevelText: String {
        guard let batteryLevel else {
            return "不明"
        }
        return "約\(batteryLevel)%"
    }
}

enum ChargeCheckSource: String, Codable, Equatable {
    case automatic
    case notification
    case manual

    var displayName: String {
        switch self {
        case .automatic:
            return "自動更新"
        case .notification:
            return "通知から確認"
        case .manual:
            return "手動更新"
        }
    }
}
