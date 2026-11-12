import SwiftUI
import UIKit

/// 想改行为就改这里，改完重新编译即可。
enum Config {
    /// true：黑着的时候不让系统自动锁屏（屏幕保持「亮着但全黑」）。
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
                AwakePanel(onBlackout: goDark)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .onAppear {
            if !showingOnboarding { goDark() }
        }
        .onDisappear {
            Brightness.restore()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // 从后台/控制中心回来，如果还该是黑的，重新压暗。
                if isDark && !showingOnboarding { Brightness.dim() }
            case .inactive, .background:
                // 离开本 App 就先还亮度，别把桌面也弄黑。
                Brightness.restore()
            @unknown default:
                break
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 22)

            Text("亮度已恢复")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("黑屏只是把屏幕压到最暗，不是关机。\n再次黑屏后，双击屏幕任意处就能回来。")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
                .lineSpacing(4)
                .padding(.top, 12)
                .padding(.horizontal, 30)

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

            Text("想退出：从屏幕底部上滑回到桌面")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.top, 18)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea())
    }
}

// MARK: - 首次启动说明

private struct OnboardingView: View {
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("黑屏")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("点「开始」之后，屏幕会立刻暗到看不见。")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 16) {
                row("doubletap", "双击屏幕任意处", "亮度立刻回来")
                row("hand.tap", "长按 2 秒", "同上，双击失灵时用")
                row("arrow.down.to.line", "切到别的 App", "亮度自动还原")
            }
            .padding(.top, 34)

            Text("它做不到真正关机——iOS 不给第三方 App 关屏权限，只能把亮度压到 0。16 Pro 是 OLED，纯黑像素不发光，看起来几乎一样。")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
                .lineSpacing(4)
                .padding(.top, 30)

            Spacer()

            Button(action: start) {
                Text("开始")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.92), in: Capsule())
            }
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea())
    }

    private func row(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
