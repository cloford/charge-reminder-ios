import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    private let userDefaults: UserDefaults
    private let dateProvider: () -> Date

    @Published private(set) var records: [ChargeCheckRecord] {
        didSet { saveRecords() }
    }

    init(
        userDefaults: UserDefaults = .standard,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
        records = Self.loadRecords(userDefaults: userDefaults)
    }

    var latestRecord: ChargeCheckRecord? {
        records.sorted { $0.checkedAt > $1.checkedAt }.first
    }

    var recentRecords: [ChargeCheckRecord] {
        Array(records.sorted { $0.checkedAt > $1.checkedAt }.prefix(20))
    }

    func recordCheck(status: BatteryStatus, source: ChargeCheckSource) {
        if source == .automatic, shouldSkipAutomaticRecord(status: status) {
            return
        }

        let record = ChargeCheckRecord(
            id: UUID(),
            checkedAt: dateProvider(),
            batteryLevel: status.level,
            batteryState: status.state,
            source: source
        )

        records.append(record)
        trimRecords()
    }

    private func shouldSkipAutomaticRecord(status: BatteryStatus) -> Bool {
        guard let latestRecord else {
            return false
        }

        let currentDate = dateProvider()
        let isRecent = currentDate.timeIntervalSince(latestRecord.checkedAt) < 300
        let isSameStatus = latestRecord.batteryLevel == status.level && latestRecord.batteryState == status.state
        return isRecent && isSameStatus
    }

    private func trimRecords() {
        let sorted = records.sorted { $0.checkedAt > $1.checkedAt }
        records = Array(sorted.prefix(100))
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        userDefaults.set(data, forKey: Keys.records)
    }

    private static func loadRecords(userDefaults: UserDefaults) -> [ChargeCheckRecord] {
        guard let data = userDefaults.data(forKey: Keys.records),
              let decoded = try? JSONDecoder().decode([ChargeCheckRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    private enum Keys {
        static let records = "chargeCheckRecords"
    }
}
