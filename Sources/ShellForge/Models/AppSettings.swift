import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var fontSize: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "fontSize")
            return val == 0 ? 14 : min(max(val, 8), 32)
        }
        set { UserDefaults.standard.set(newValue, forKey: "fontSize") }
    }

    var themeID: String {
        get { UserDefaults.standard.string(forKey: "themeID") ?? "solarized-dark" }
        set { UserDefaults.standard.set(newValue, forKey: "themeID") }
    }

    var hapticEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }

    var bellEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "bellEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "bellEnabled") }
    }
}
