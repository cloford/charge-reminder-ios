import Foundation

@MainActor
final class ScoreStore: ObservableObject {
    @Published private(set) var scores: [ChargeScore] {
        didSet { saveScores() }
    }

    init() {
        scores = Self.loadScores()
    }

    var todayScore: ChargeScore {
        score(for: DateTimeHelper.dayKey())
    }

    var sevenDayAverage: Double {
        let calendar = Calendar.current
        let keys = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map(DateTimeHelper.dayKey)
        }

        let totals = keys.map { score(for: $0).total }
        guard !totals.isEmpty else { return 0 }
        return Double(totals.reduce(0, +)) / Double(totals.count)
    }

    func markOpenedAfterNotification() {
        updateToday { $0.openedAfterNotification = true }
    }

    func markChargingWhenChecked() {
        updateToday { $0.wasChargingWhenChecked = true }
    }

    func markEnoughBatteryInMorning() {
        updateToday { $0.hadEnoughBatteryInMorning = true }
    }

    private func updateToday(_ update: (inout ChargeScore) -> Void) {
        let key = DateTimeHelper.dayKey()
        var score = score(for: key)
        update(&score)
        upsert(score)
    }

    private func score(for key: String) -> ChargeScore {
        scores.first(where: { $0.dayKey == key }) ?? .empty(dayKey: key)
    }

    private func upsert(_ score: ChargeScore) {
        if let index = scores.firstIndex(where: { $0.dayKey == score.dayKey }) {
            scores[index] = score
        } else {
            scores.append(score)
        }
    }

    private func saveScores() {
        guard let data = try? JSONEncoder().encode(scores) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Keys.scores)
    }

    private static func loadScores() -> [ChargeScore] {
        guard let data = UserDefaults.standard.data(forKey: Keys.scores),
              let decoded = try? JSONDecoder().decode([ChargeScore].self, from: data) else {
            return []
        }
        return decoded
    }

    private enum Keys {
        static let scores = "chargeScores"
    }
}
