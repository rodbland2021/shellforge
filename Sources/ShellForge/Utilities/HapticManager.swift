import UIKit

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let settings = AppSettings.shared
        guard settings.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let settings = AppSettings.shared
        guard settings.hapticEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
