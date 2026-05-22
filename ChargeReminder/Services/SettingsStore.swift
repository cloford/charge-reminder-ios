import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private let userDefaults: UserDefaults

    @Published var notificationSettings: [NotificationSetting] {
        didSet { save(notificationSettings, forKey: Keys.notificationSettings) }
    }

    @Published var wakeUpSetting: WakeUpSetting {
        didSet { save(wakeUpSetting, forKey: Keys.wakeUpSetting) }
    }

    @Published var lowBatteryThreshold: Int {
        didSet { userDefaults.set(lowBatteryThreshold, forKey: Keys.lowBatteryThreshold) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { userDefaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        notificationSettings = Self.load([NotificationSetting].self, forKey: Keys.notificationSettings, userDefaults: userDefaults) ?? NotificationSetting.defaultSettings
        wakeUpSetting = Self.load(WakeUpSetting.self, forKey: Keys.wakeUpSetting, userDefaults: userDefaults) ?? WakeUpSetting.defaultValue
        lowBatteryThreshold = userDefaults.object(forKey: Keys.lowBatteryThreshold) as? Int ?? 50
        hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    func updateNotification(_ setting: NotificationSetting) {
        guard let index = notificationSettings.firstIndex(where: { $0.id == setting.id }) else {
            return
        }
        notificationSettings[index] = setting
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, userDefaults: UserDefaults) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private enum Keys {
        static let notificationSettings = "notificationSettings"
        static let wakeUpSetting = "wakeUpSetting"
        static let lowBatteryThreshold = "lowBatteryThreshold"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
