import SwiftUI
import UIKit

/// 想改行为就改这里，改完重新编译即可。
enum Config {
    /// true：在本 App 前台时不让系统自动锁屏。
    /// 注意：切到 miniwatts 之后这条就失效了，系统设置里「自动锁定」必须改成「永不」。
    static let keepScreenAwake = true
    /// 双击任意处唤醒。
    static let wakeByDoubleTap = true
    /// 长按 2 秒唤醒（双击没反应时的备用通道）。
    static let wakeByLongPress = true
    /// 第一次装好先给一页说明，免得你以为手机坏了。
    static let showOnboardingOnFirstLaunch = true
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var isDark = true
    @State private var showingOnboarding: Bool

    private static let onboardingKey = "hasSeenOnboarding"

    init() {
        let seen = UserDefaults.standard.bool(forKey: RootView.onboardingKey)
        _showingOnboarding = State(initialValue: Config.showOnboardingOnFirstLaunch && !seen)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showingOnboarding {
                OnboardingView(start: startFromOnboarding)
            } else if isDark {
                DarkLayer(onWake: wake)
            } else {
                AwakePanel(onBlackout: goDark, onRestore: restoreBrightness)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .onAppear {
            if !showingOnboarding { goDark() }
        }
        .onChange(of: scenePhase) { _, phase in
            // 只在回到前台时重新压暗；离开前台绝不还原——
            // 压暗之后切到 miniwatts，屏幕必须保持全黑。
            if phase == .active && isDark && !showingOnboarding {
                Brightness.dim()
            }
        }
    }

    // MARK: - 状态切换

    private func startFromOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        showingOnboarding = false
        goDark()
    }

    private func goDark() {
        withAnimation(.easeInOut(duration: 0.15)) { isDark = true }
        UIApplication.shared.isIdleTimerDisabled = Config.keepScreenAwake
        Brightness.dim()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func wake() {
        withAnimation(.easeInOut(duration: 0.15)) { isDark = false }
        UIApplication.shared.isIdleTimerDisabled = false
        Brightness.restore()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func restoreBrightness() {
        Brightness.restore()
        isDark = false
        UIApplication.shared.isIdleTimerDisabled = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - 全黑层

private struct DarkLayer: View {
    let onWake: () -> Void

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(count: Config.wakeByDoubleTap ? 2 : 1, perform: onWake)
            .onLongPressGesture(minimumDuration: 2.0) {
                if Config.wakeByLongPress { onWake() }
            }
    }
}

// MARK: - 唤醒后的面板

private struct AwakePanel: View {
    let onBlackout: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 20)

            Text("亮度已恢复")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("再次黑屏后，切到 miniwatts，屏幕会一直是全黑的——\n它在前台，照样记数据。")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
                .lineSpacing(4)
                .padding(.top, 12)
                .padding(.horizontal, 28)

            Spacer()

            Button(action: onBlackout) {
                HStack(spacing: 8) {
                    Image(systemName: "power")
                    Text("再次黑屏")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white.opacity(0.92), in: Capsule())
            }
            .padding(.horizontal, 40)

            Button(action: onRestore) {
                Text("只还原亮度，不黑屏")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.horizontal, 40)
            .padding(.top, 6)

            Text("被卡在全黑时：拉控制中心直接调亮度，或双击屏幕回来")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.32))
                .padding(.top, 10)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea())
    }
}

// MARK: - 首次启动说明

private struct OnboardingView: View {
    let start: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("黑屏")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 60)

                Text("让 miniwatts 留在前台记数据，屏幕却暗着。")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)

                Text("点「开始」之后屏幕会立刻暗到看不见。亮度是全局的，切到 miniwatts 也一样黑。")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineSpacing(4)
                    .padding(.top, 14)

                Divider().overlay(Color.white.opacity(0.08)).padding(.vertical, 26)

                Text("装好之后必须先做两件事")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))

                VStack(alignment: .leading, spacing: 16) {
                    step("1", "设置 › 显示与亮度 › 自动锁定", "改成「永不」，否则锁屏会把 miniwatts 挤出前台")
                    step("2", "设置 › 辅助功能 › 显示与文字大小", "关掉「自动亮度」，否则它会跟你抢亮度")
                }
                .padding(.top, 16)

                Divider().overlay(Color.white.opacity(0.08)).padding(.vertical, 26)

                Text("想不切 App 就熄暗？")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))

                Text("本 App 带了两个快捷指令：「熄暗屏幕」和「还原屏幕亮度」。在「快捷指令」里把它们绑到\n设置 › 辅助功能 › 触控 › 轻点背面 › 双击 / 三击。\n这样在 miniwatts 里双击后盖，屏幕直接暗下去，它还留在前台。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineSpacing(5)
                    .padding(.top, 10)

                Spacer(minLength: 40)

                Button(action: start) {
                    Text("开始")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white.opacity(0.92), in: Capsule())
                }
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea())
    }

    private func step(_ index: String, _ path: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(index)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(0.75), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(path)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
