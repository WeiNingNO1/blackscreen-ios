import AVFoundation
import UIKit

/// 让 App 在切到后台之后依然活着，并持续把亮度压回 0。
///
/// 为什么需要它：
/// `UIScreen.brightness = 0` 是全局设置，但 iOS 在别的 App 到前台时（或自动亮度
/// 介入时）会把它抬回系统最低值。只压一次顶不住，必须在后台一直盯着。
///
/// 原理：Info.plist 里声明 `UIBackgroundModes = audio`，然后循环播放一段静音。
/// 系统认为进程在放音频就不会挂起它，于是每 0.4 秒都能检查一次亮度，
/// 一被抬起就立刻压回 0。
final class BackgroundKeeper {

    static let shared = BackgroundKeeper()

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var silenceURL: URL?

    private init() {}

    /// 开始保活 + 持续压暗。
    func start() {
        startAudio()
        startTimer()
    }

    /// 停止保活，把音频会话还回去。
    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - 定时压暗

    private func startTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 0.4, repeats: true) { _ in
            // 只在还该是黑的时候压；Brightness 内部记着原亮度，不会把自己写死。
            Brightness.dim()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - 静音保活

    private func startAudio() {
        guard player == nil else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            let p = try AVAudioPlayer(contentsOf: try silenceFileURL())
            p.numberOfLoops = -1      // 无限循环
            p.volume = 0
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            // 老实降级：保活失败就只剩前台那一次压暗。
        }
    }

    /// 现造一段 1 秒的单声道 16-bit 静音 WAV。
    private func silenceFileURL() throws -> URL {
        if let url = silenceURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let sampleRate = 8000
        let frames = sampleRate                  // 1 秒
        let dataSize = frames * 2                // 16-bit 单声道

        var data = Data()
        func ascii(_ s: String) { data.append(contentsOf: Array(s.utf8)) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

        ascii("RIFF"); u32(UInt32(36 + dataSize)); ascii("WAVE")
        ascii("fmt "); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate * 2))
        u16(2); u16(16)
        ascii("data"); u32(UInt32(dataSize))
        data.append(Data(count: dataSize))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blackscreen-silence.wav")
        try data.write(to: url, options: .atomic)
        silenceURL = url
        return url
    }
}

/// 熄暗 / 还原的统一入口，界面和快捷指令都走这里。
enum DimController {

    static func dim() {
        Brightness.dim()
        BackgroundKeeper.shared.start()
    }

    static func restore() {
        BackgroundKeeper.shared.stop()
        Brightness.restore()
    }
}
