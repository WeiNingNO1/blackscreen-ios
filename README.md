# 黑屏 / BlackScreen (iOS)

启动即把屏幕压到最暗的全屏纯黑 App。iPhone 16 Pro 是 OLED，纯黑像素不发光，所以看起来基本等同于关机。

## 它做了什么

| 能力 | 实现 |
| --- | --- |
| 全屏纯黑 | `Color.black` + `ignoresSafeArea`，盖住刘海和灵动岛 |
| 亮度压到 0 | `UIScreen.brightness = 0`（进入前先记住原亮度） |
| 隐藏状态栏 / Home 条 | `statusBarHidden(true)` + `persistentSystemOverlays(.hidden)` |
| 黑着不自动锁屏 | `UIApplication.isIdleTimerDisabled = true` |
| 离开即还原 | 切后台、控制中心下拉时把亮度还回去 |
| 首次启动说明 | 只有第一次装好会显示，避免“屏怎么黑了” |

## 它做不到

- **真正关屏 / 锁屏**。iOS 对第三方 App 不开放关屏接口，`brightness = 0` 是最暗，不是断电。私有 API（SpringBoardServices）需要越狱或 TrollStore，App Store 必拒。
- 挡住来电、闹钟、通知横幅的亮屏。只能自己开「专注模式」。

## 交互

| 动作 | 结果 |
| --- | --- |
| 双击屏幕任意处 | 亮度还原 + 显示面板 |
| 长按 2 秒 | 同上（双击失灵时的备用） |
| 从底部上滑 / 按侧键 | 离开 App，亮度自动还原 |
| 面板上的「再次黑屏」 | 回到全黑 |

黑屏时有一次轻微震动反馈，看不见屏幕也知道手势生效了。

## 调参

`Sources/RootView.swift` 顶部 `Config`：

```swift
static let keepScreenAwake = true            // false: 让系统到点自动锁屏（真熄屏）
static let wakeByDoubleTap = true
static let wakeByLongPress = true
static let showOnboardingOnFirstLaunch = true
```

## 出 IPA（Windows 上也能出）

没有 Mac 就走 GitHub Actions 的 macOS runner，产出**未签名** ipa：

1. GitHub 建一个空仓（public 不消耗额度）
2. 把本目录**里面的内容**（含 `.github/`）推到仓库根
3. Actions → `build-ipa` → 跑完下载 artifact `BlackScreen-unsigned-ipa`

有 Mac 的话更快：

```bash
brew install xcodegen
xcodegen generate
open BlackScreen.xcodeproj      # 或者直接 xcodebuild -scheme BlackScreen
```

> `BlackScreen.xcodeproj` 是 `xcodegen generate` 生成的，被 `.gitignore` 排除了，别手改。

## 签名（你有证书，这步你熟）

未签名 ipa 装不上机。**bundle id 必须和描述文件里的一致**，二选一：

- 改 `project.yml` 的 `PRODUCT_BUNDLE_IDENTIFIER: com.blackscreen.minimal` 再重新出包
- 或者签名工具里覆盖 bundle id（zsign / Sideloadly 都支持）

```bash
zsign -k cert.p12 -p 你的密码 -m dev.mobileprovision -o BlackScreen-signed.ipa BlackScreen.ipa
```

图形工具直接拖进去也行：Sideloadly、轻松签、ESign。

## 卡在全黑怎么办

1. 拉**控制中心**手动调亮度——那是系统亮度，App 抢不走
2. 双击屏幕（本 App 的还原手势）
3. 都不行就长按「侧键 + 音量上」硬重启，亮度会回到默认

## 已知限制

- 强制退出 App 时如果正好是黑屏，系统亮度会停在 0；下次进 App 或拉控制中心可恢复
- 自动亮度会和 0 打架，建议关掉「设置 > 辅助功能 > 显示与文字大小 > 自动亮度」
- 14 Pro 起的「常亮显示」在锁屏状态仍有微光，这是系统行为，App 管不了

## 目录

```
project.yml                        XcodeGen 工程描述
Sources/BlackScreenApp.swift       入口
Sources/RootView.swift             界面状态机 + 可调参数
Sources/Brightness.swift           亮度存取与还原
Sources/Info.plist                 纯黑启动屏、竖屏、隐藏状态栏
Sources/Assets.xcassets/           App 图标 + 启动色
.github/workflows/build-ipa.yml    CI 出 ipa
tools/make_icon.py                 重新生成图标
```
