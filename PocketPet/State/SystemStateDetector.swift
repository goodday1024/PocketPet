import Foundation
import MediaPlayer
import UIKit
import Combine

/// 自动检测的系统状态。检测结果来源真实系统，绝不伪造。
public enum DetectedSystemEvent: Equatable {
    case playingMusic(title: String?, artist: String?)
    case stoppedMusic
    case screenDimmed        // 屏幕变暗 / 即将息屏
    case screenAwake         // 屏幕亮起 / 恢复活跃
}

/// 系统状态自动检测器。
///
/// 能力与边界（如实告知）：
/// - **听歌**：通过 `MPNowPlayingInfoCenter` 与 `MPMusicPlayerController` 检测系统级"正在播放"，
///   覆盖 Apple Music、播客、部分第三方播放器（前提是它们接入了系统 Now Playing）。
/// - **息屏打盹**：通过 `UIScreen.brightness` 变化 + 状态判断，亮屏恢复。
/// - **导航 / 发消息 / 打游戏**：iOS 沙盒禁止第三方 App 检测其他 App 的这些行为
///   （Apple 隐私红线），本项目不做这类检测，保留为用户手动触发场景。
@MainActor
public final class SystemStateDetector: ObservableObject {

    /// 当前是否检测到系统正在播放音乐。
    @Published public private(set) var isPlayingMusic: Bool = false
    /// 当前播放的曲目信息。
    @Published public private(set) var nowPlayingTitle: String?
    @Published public private(set) var nowPlayingArtist: String?
    /// 屏幕是否处于变暗 / 息屏状态。
    @Published public private(set) var isScreenDimmed: Bool = false
    /// 是否启用自动检测（可在设置关闭）。
    @Published public var autoDetectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoDetectionEnabled, forKey: autoDetectionKey)
            if autoDetectionEnabled { start() } else { stop() }
        }
    }

    /// 检测到系统事件时回调（PetStore 订阅）。
    public var onEvent: ((DetectedSystemEvent) -> Void)?

    private let autoDetectionKey = "PocketPet.autoDetect.v1"
    private var pollTask: Task<Void, Never>?

    public init() {
        self.autoDetectionEnabled = UserDefaults.standard.object(forKey: autoDetectionKey) as? Bool ?? true
    }

    // MARK: - 启停

    public func start() {
        guard autoDetectionEnabled else { return }
        startMusicDetection()
        startScreenDetection()
    }

    public func stop() {
        stopMusicDetection()
        stopScreenDetection()
        // 关闭时复位检测状态，避免残留
        if isPlayingMusic {
            isPlayingMusic = false
            onEvent?(.stoppedMusic)
        }
    }

    // MARK: - 听歌检测

    private func startMusicDetection() {
        // 系统级 Now Playing 无法直接 KVO，用定时轮询（每 5 秒）。
        // 这是检测"任意播放器正在播放"最可靠的纯客户端方案。
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            while !Task.isCancelled && autoDetectionEnabled {
                refreshNowPlaying()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func stopMusicDetection() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// 读取系统 Now Playing 信息判断是否在播放。
    private func refreshNowPlaying() {
        let center = MPNowPlayingInfoCenter.default()
        let info = center.nowPlayingInfo ?? [:]
        let title = info[MPMediaItemPropertyTitle] as? String
        let artist = info[MPMediaItemPropertyArtist] as? String
        // playbackRate > 0 视为播放中（0 或缺失视为暂停）
        let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0

        let playing: Bool
        if let t = title, !t.isEmpty {
            playing = playbackRate > 0
        } else {
            playing = false
        }

        let wasPlaying = isPlayingMusic
        isPlayingMusic = playing
        nowPlayingTitle = title
        nowPlayingArtist = artist

        if playing && !wasPlaying {
            onEvent?(.playingMusic(title: title, artist: artist))
        } else if !playing && wasPlaying {
            onEvent?(.stoppedMusic)
        }
    }

    // MARK: - 屏幕状态检测

    private func startScreenDetection() {
        // 监听系统亮度变化通知（用户调亮/调暗、系统自动调暗均会触发）。
        // 不使用 KVO observe(_:options:)，避免在闭包中捕获 self 的并发告警。
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenBrightnessChanged),
            name: UIScreen.brightnessDidChangeNotification, object: nil)
        // 用初始亮度初始化一次状态
        handleBrightness(UIScreen.main.brightness)
    }

    private func stopScreenDetection() {
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    @objc private func screenBrightnessChanged() {
        // UIScreen.brightnessDidChangeNotification 在主线程派发，直接处理即可。
        handleBrightness(UIScreen.main.brightness)
    }

    private func handleBrightness(_ brightness: CGFloat) {
        let dimmed = brightness < 0.1
        let wasDimmed = isScreenDimmed
        isScreenDimmed = dimmed
        if dimmed && !wasDimmed {
            onEvent?(.screenDimmed)
        } else if !dimmed && wasDimmed {
            onEvent?(.screenAwake)
        }
    }
}
