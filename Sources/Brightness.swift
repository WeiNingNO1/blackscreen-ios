import UIKit

/// 系统亮度管家。
///
/// - 熄暗时把亮度压到 0，并把「熄暗之前」的亮度记到 UserDefaults，
///   这样 App 被杀掉、重装后重启也能还原回去。
/// - 亮度是全局设置，不是本 App 的画面亮度。压到 0 之后切到别的 App，
///   屏幕仍然是黑的 —— 这正是「让 miniwatts 留在前台记录、屏幕却是暗的」的实现方式。
enum Brightness {

    private static let storageKey = "savedBrightness"

    private static var savedValue: Double? {
        get {
            let defaults = UserDefaults.standard
            guard defaults.object(forKey: storageKey) != nil else { return nil }
            return defaults.double(forKey: storageKey)
        }
        set {
            let defaults = UserDefaults.standard
            if let newValue {
                defaults.set(newValue, forKey: storageKey)
            } else {
                defaults.removeObject(forKey: storageKey)
            }
        }
    }

    /// 取当前活跃场景的屏幕；取不到再退回 UIScreen.main。
    private static var targetScreen: UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let active = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return active.screen
        }
        return scenes.first?.screen ?? UIScreen.main
    }

    /// 压到最暗。只记录第一次的原亮度，避免被自己写进去的 0 覆盖。
    static func dim() {
        guard let screen = targetScreen else { return }
        if savedValue == nil { savedValue = Double(screen.brightness) }
        screen.brightness = 0
    }

    /// 还原到熄暗之前的亮度。
    static func restore() {
        guard let screen = targetScreen, let value = savedValue else { return }
        screen.brightness = CGFloat(value)
        savedValue = nil
    }
}
