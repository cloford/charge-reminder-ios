import Foundation

enum BatteryJudgement {
    static func recommendation(
        status: BatteryStatus,
        wakeUpSetting: WakeUpSetting,
        lowBatteryThreshold: Int,
        now: Date = Date()
    ) -> ChargeRecommendation {
        guard let level = status.level else {
            return .unknown
        }

        if status.state == .charging || status.state == .full {
            return .safe
        }

        let hoursUntilWakeUp = DateTimeHelper.hoursUntil(
            hour: wakeUpSetting.hour,
            minute: wakeUpSetting.minute,
            from: now
        )

        if hoursUntilWakeUp >= 8, level < 60 {
            return .chargeRecommended
        }

        if level >= 80 {
            return .safe
        }

        if level <= max(lowBatteryThreshold - 1, 0) {
            return .chargeRecommended
        }

        return .caution
    }
}
