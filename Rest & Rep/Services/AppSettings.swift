import SwiftUI

/// UserDefaults keys and defaults shared by `@AppStorage` in views and by the services.
enum AppSettings {
    static let soundKey = "settings.sound"
    static let hapticsKey = "settings.haptics"
    static let keepAwakeKey = "settings.keepAwake"
    static let appearanceKey = "settings.appearance"
    static let lastCustomKey = "lastCustomConfig"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            soundKey: true,
            hapticsKey: true,
            keepAwakeKey: true,
            appearanceKey: Appearance.dark.rawValue
        ])
    }

    static var soundEnabled: Bool { UserDefaults.standard.bool(forKey: soundKey) }
    static var hapticsEnabled: Bool { UserDefaults.standard.bool(forKey: hapticsKey) }
    static var keepAwake: Bool { UserDefaults.standard.bool(forKey: keepAwakeKey) }
}

/// Dark by default, with light mode available.
enum Appearance: String, CaseIterable, Identifiable {
    case dark, light, system

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .system: "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}

extension TimerConfig {
    /// JSON round-trip for storing the last-used custom timer in `@AppStorage`.
    var encoded: Data? { try? JSONEncoder().encode(self) }

    init?(data: Data?) {
        guard let data, let config = try? JSONDecoder().decode(TimerConfig.self, from: data) else {
            return nil
        }
        self = config
    }
}
