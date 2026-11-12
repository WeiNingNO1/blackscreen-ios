import UIKit

/// 系统亮度管家。
///
/// 进黑屏时把亮度压到 0，离开时把「进来之前」的亮度原样还回去。
/// 只记录第一次的原亮度，避免被自己写进去的 0 覆盖掉。
enum Brightness {

    private static var savedValue: CGFloat?

    /// 取当前活跃场景的屏幕；取不到再退回 UIScreen.main。
    private static var targetScreen: UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let active = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return active.screen
        }
        return scenes.first?.screen ?? UIScreen.main
    }

    /// 压到最暗（0.0 是系统允许的最小值，不是断电）。
    static func dim() {
        guard let screen = targetScreen else { return }
        if savedValue == nil { savedValue = screen.brightness }
        screen.brightness = 0
    }

    /// 还原到进入黑屏之前的亮度。
    static func restore() {
        guard let screen = targetScreen, let value = savedValue else { return }
        screen.brightness = value
        savedValue = nil
    }
}
