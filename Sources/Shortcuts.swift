import AppIntents

/// 「熄暗屏幕」——给快捷指令 / 轻点背面 / 控制中心调用。
///
/// 关键点：`openAppWhenRun = false`，调用时不会把本 App 顶到前台，
/// 所以 miniwatts 能一直留前台记录，屏幕却已经压暗了。
struct DimScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "熄暗屏幕"
    static let description = IntentDescription("把屏幕亮度压到 0，并在后台持续压住，当前 App 留在前台继续运行。")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { DimController.dim() }
        return .result()
    }
}

/// 「还原屏幕亮度」——恢复到熄暗之前记下的数值。
struct RestoreScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "还原屏幕亮度"
    static let description = IntentDescription("停止压暗，把亮度恢复到熄暗之前的数值。")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { DimController.restore() }
        return .result()
    }
}

/// 让这两个动作直接出现在「快捷指令」App 里，不必手动搭流程。
struct BlackScreenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DimScreenIntent(),
            phrases: [
                "\(.applicationName) 熄暗屏幕",
                "\(.applicationName) 熄暗",
                "用 \(.applicationName) 变暗"
            ],
            shortTitle: "熄暗",
            systemImageName: "moon.fill"
        )
        AppShortcut(
            intent: RestoreScreenIntent(),
            phrases: [
                "\(.applicationName) 还原亮屏",
                "用 \(.applicationName) 点亮"
            ],
            shortTitle: "还原",
            systemImageName: "sun.max.fill"
        )
    }
}
