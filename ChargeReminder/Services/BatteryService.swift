import UIKit

protocol BatteryServiceProtocol {
    func currentStatus() -> BatteryStatus
}

final class BatteryService: BatteryServiceProtocol {
    func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    func currentStatus() -> BatteryStatus {
        startMonitoring()

        let rawLevel = UIDevice.current.batteryLevel
        let level = rawLevel >= 0 ? Int((rawLevel * 100).rounded()) : nil

        let state: BatteryConnectionState
        switch UIDevice.current.batteryState {
        case .unplugged:
            state = .unplugged
        case .charging:
            state = .charging
        case .full:
            state = .full
        case .unknown:
            fallthrough
        @unknown default:
            state = .unknown
        }

        return BatteryStatus(level: level, state: state)
    }
}
