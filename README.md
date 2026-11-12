# 黑屏 / BlackScreen (iOS)

**用途**：让 miniwatts 留在前台继续记录充电数据，同时把整块屏幕压暗到看不出东西。

iPhone 16 Pro 是 OLED，纯黑像素不发光，亮度 0 基本等于一块关着的玻璃。

## 为什么不是「悬浮窗」

iOS 不允许第三方 App 画在别的 App 上面。唯一的浮层是画中画（PiP），它：

- 最多巴掌大小，系统不允许放大到全屏
- 只是「挡住」，不降低屏幕发光，屏幕照样亮

但你的目的不需要浮层：**亮度是全局设置**。把 `UIScreen.brightness` 设成 0 之后，切到 miniwatts，屏幕依然是黑的，而 miniwatts 留在前台继续跑。

## 装好后必做的两件事

| 设置 | 路径 | 为什么要改 |
| --- | --- | --- |
| 自动锁定 → **永不** | 设置 › 显示与亮度 › 自动锁定 | 锁屏会把 miniwatts 挤出前台，记录就断了。本 App 只在自己前台时能顶住自动锁屏，管不到别的 App |
| 自动亮度 → **关** | 设置 › 辅助功能 › 显示与文字大小 › 自动亮度 | 它会跟亮度 0 打架，环境一变亮就把屏幕提起来 |

## 两种用法

### 一、轻点背面（推荐，不用切 App）

App 内置两个快捷指令：**「熄暗屏幕」**和**「还原屏幕亮度」**。

1. 打开「快捷指令」App，能看到它们已经在那儿
2. 设置 › 辅助功能 › 触控 › 轻点背面 › 双击 → 选「熄暗屏幕」
3. 同一页 › 三击 → 选「还原屏幕亮度」

用法：打开 miniwatts（它在前台记数据）→ **双击后盖** → 屏幕暗掉，miniwatts 还在前台 → 三击后盖还原。

这两个动作 `openAppWhenRun = false`，所以不会把黑屏 App 顶到前台，你的 miniwatts 不会被踢走。

### 二、直接开 App

打开本 App 就是全黑的。双击屏幕任意处唤出面板，面板上有：

- **再次黑屏** —— 回全黑
- **只还原亮度，不黑屏** —— 把亮度还回去，留在面板里

## 卡在全黑怎么办

1. 拉**控制中心**直接调亮度（系统亮度，App 抢不走）
2. 双击屏幕回到面板
3. 三击后盖（如果你绑了「还原屏幕亮度」）
4. 都不行：侧键 + 音量上加长按硬重启

## 它做不到

- **真正关屏 / 锁屏**。iOS 不给第三方 App 关屏权限，`brightness = 0` 是最暗，不是断电。
- **跨 App 浮层**（见上）。
- **替别的 App 顶住自动锁屏**。所以「自动锁定 = 永不」必须手动设。
- 挡住来电、闹钟、通知横幅的亮屏。

## 参数

`Sources/RootView.swift` 顶部 `Config`：

```swift
static let keepScreenAwake = true            // 本 App 前台时是否禁止自动锁屏
static let wakeByDoubleTap = true
static let wakeByLongPress = true
static let showOnboardingOnFirstLaunch = true
```

## 构建

已接 GitHub Actions，推一次就出未签名 ipa（仓库：`WeiNingNO1/blackscreen-ios`）。

本地有 Mac 也可以：

```bash
bash build-on-mac.sh
```

## 签名

产物是未签名 ipa，装不上机。**bundle id 必须和描述文件一致**：

- 当前 `PRODUCT_BUNDLE_IDENTIFIER` = `com.blackscreen.minimal`
- 对不上就改 `project.yml` 里那一行，重新出包
- 或者由签名工具覆盖

```bash
zsign -k cert.p12 -p 密码 -m dev.mobileprovision -o signed.ipa BlackScreen.ipa
```

## 目录

```
project.yml                        XcodeGen 工程描述
Sources/BlackScreenApp.swift       入口
Sources/RootView.swift             界面状态机 + 可调参数
Sources/Brightness.swift           全局亮度存取与还原（落盘到 UserDefaults）
Sources/Shortcuts.swift            熄暗 / 还原 两个 App Intent
Sources/Info.plist                 纯黑启动屏、竖屏、隐藏状态栏
Sources/Assets.xcassets/           App 图标 + 启动色
.github/workflows/build-ipa.yml    CI 出 ipa
tools/make_icon.py                 重新生成图标
```
