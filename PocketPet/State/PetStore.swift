import Foundation
import SwiftUI
import ActivityKit
import Combine
import UIKit

/// 宠物与状态总管：维护当前场景状态、灵动岛 Live Activity，
/// 并把各状态持续时间 / 次数上报给 `AchievementStore`，
/// 同时与 `ProfileStore` 联动实现宠物切换 / 解锁。
@MainActor
public final class PetStore: ObservableObject {

    public let profile: ProfileStore
    public let achievements: AchievementStore

    @Published public var currentState: PetState = .idle
    @Published public var liveActivityActive: Bool = false
    @Published public var scenarioTitle: String = ""
    @Published public var scenarioSubtitle: String = ""
    /// 新解锁的宠物（待提示）。
    @Published public var newlyUnlockedPets: [PetSpecies] = []
    /// 是否让小猫常驻灵动岛（默认开启）。
    @Published public var keepOnIsland: Bool {
        didSet { UserDefaults.standard.set(keepOnIsland, forKey: keepOnIslandKey) }
    }

    /// 当前状态来源：自动检测优先级高于手动触发。
    @Published public private(set) var stateSource: StateSource = .manual
    /// 系统状态自动检测器。
    public let detector = SystemStateDetector()
    /// 当前是否有自动检测占据的状态（用于避免手动操作误打断）。
    private var autoStateActive: Bool = false

    /// 当前宠物（绑定到 profile）。
    public var pet: Pet { profile.currentPet }

    /// 空闲多久（无任何场景）后进入打盹。
    private let idleToSleep: TimeInterval = 30
    private let keepOnIslandKey = "PocketPet.keepOnIsland.v1"
    private var idleTask: Task<Void, Never>?
    private var stateStartedAt: Date = .init()
    private var tickerTask: Task<Void, Never>?
    /// 续期任务：iOS Live Activity 默认 8 小时（无推送）自动结束，
    /// App 在前台时定期检查并重启，让小猫"一直保持在灵动岛上"。
    private var keepAliveTask: Task<Void, Never>?

    /// 状态来源。
    public enum StateSource: Equatable {
        case manual      // 用户手动触发场景
        case autoMusic   // 系统检测到播放音乐
        case autoScreen  // 系统检测到息屏
    }

    public init(profile: ProfileStore, achievements: AchievementStore) {
        self.profile = profile
        self.achievements = achievements
        self.stateStartedAt = Date()
        self.scenarioTitle = PetState.idle.defaultTitle
        self.keepOnIsland = UserDefaults.standard.object(forKey: "PocketPet.keepOnIsland.v1") as? Bool ?? true
        startTicker()
        startKeepAlive()
        resetIdleTimer()
        bindDetector()
    }

    // MARK: - 自动检测接入

    private func bindDetector() {
        detector.onEvent = { [weak self] event in
            Task { @MainActor in self?.handleSystemEvent(event) }
        }
        if detector.autoDetectionEnabled { detector.start() }
    }

    /// 处理真实系统事件：自动状态优先于手动。
    private func handleSystemEvent(_ event: DetectedSystemEvent) {
        switch event {
        case .playingMusic(let title, let artist):
            // 自动听歌：打断当前任何状态（含手动），进入摇摆
            autoStateActive = true
            stateSource = .autoMusic
            let t = title ?? PetState.music.defaultTitle
            let s = artist ?? NSLocalizedString("music.swing", value: "跟随节奏摇摆", comment: "")
            enterInternal(.music, title: String(format: NSLocalizedString("fmt.listening", value: "正在听: %@", comment: ""), t), subtitle: s)
            cancelIdleTimer()
        case .stoppedMusic:
            guard stateSource == .autoMusic else { return }
            autoStateActive = false
            stateSource = .manual
            backToIdleOrSleep()
        case .screenDimmed:
            // 息屏打盹：自动进入 sleeping（即便用户在手动场景，息屏也优先生效）
            autoStateActive = true
            stateSource = .autoScreen
            enterInternal(.sleeping,
                          title: PetState.sleeping.defaultTitle,
                          subtitle: NSLocalizedString("sleep.hint", value: "嘘，它在打盹…", comment: ""))
            cancelIdleTimer()
        case .screenAwake:
            guard stateSource == .autoScreen else { return }
            autoStateActive = false
            stateSource = .manual
            backToIdleOrSleep()
        }
    }

    /// 切回待机，或自动打盹（视空闲时长）。
    private func backToIdleOrSleep() {
        enterInternal(.idle, title: PetState.idle.defaultTitle, subtitle: "")
        resetIdleTimer()
    }

    /// 内部切换：不区分来源，统一更新状态与灵动岛，不发触感（自动事件免打扰）。
    private func enterInternal(_ state: PetState, title: String, subtitle: String) {
        flushCurrentDuration()
        currentState = state
        stateStartedAt = Date()
        scenarioTitle = title
        scenarioSubtitle = subtitle
        achievements.collect(state: state)
        updateOrStartLiveActivity(for: state)
        checkPetUnlocks()
    }

    // MARK: - 状态切换

    /// 手动进入指定场景状态。
    /// 若当前处于自动检测状态（听歌/息屏），手动操作会被忽略，避免打断真实系统状态。
    public func enter(_ state: PetState,
                      title: String = "",
                      subtitle: String = "",
                      presentLiveActivity: Bool = true) {
        // 自动状态激活时，手动场景让位（除非用户切换的就是结束当前手动场景）
        if autoStateActive {
            return
        }
        flushCurrentDuration()
        currentState = state
        stateSource = .manual
        stateStartedAt = Date()
        scenarioTitle = title.isEmpty ? state.defaultTitle : title
        scenarioSubtitle = subtitle
        achievements.collect(state: state)
        Haptics.tap(state: state)

        // 计次类（导航 / 消息）立即 +1
        if state == .navigating { achievements.incrementCount(for: .navigation) }

        if presentLiveActivity {
            updateOrStartLiveActivity(for: state)
        }
        resetIdleTimer()
        checkPetUnlocks()
    }

    /// 结束当前场景，回到待机。
    /// 开启常驻时仅把灵动岛更新为待机，**不结束** Live Activity，让小猫一直留在灵动岛。
    /// 自动检测激活时，结束操作只复位手动状态，不打断自动状态。
    public func endScenario() {
        if autoStateActive {
            // 自动状态在跑，手动"结束"无意义，直接返回
            return
        }
        flushCurrentDuration()
        currentState = .idle
        stateSource = .manual
        stateStartedAt = Date()
        scenarioTitle = PetState.idle.defaultTitle
        scenarioSubtitle = ""
        Haptics.light()
        if keepOnIsland {
            updateOrStartLiveActivity(for: .idle)
        } else {
            endLiveActivity()
        }
        resetIdleTimer()
        checkPetUnlocks()
    }

    /// 发送一条消息（娱乐状态下的子动作）。
    public func sendMessage() {
        achievements.incrementCount(for: .messaging)
        Haptics.light()
        checkPetUnlocks()
    }

    /// 切换当前宠物，并同步更新灵动岛展示。
    public func switchPet(to id: UUID) {
        profile.switchTo(id)
        Haptics.success()
        if liveActivityActive {
            updateLiveActivity(to: currentState, title: scenarioTitle, subtitle: scenarioSubtitle)
        }
    }

    // MARK: - 空闲 -> 打盹

    private func resetIdleTimer() {
        idleTask?.cancel()
        if currentState == .idle || currentState == .sleeping {
            idleTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(idleToSleep))
                if !Task.isCancelled { fallAsleep() }
            }
        }
    }

    private func cancelIdleTimer() {
        idleTask?.cancel()
        idleTask = nil
    }

    private func fallAsleep() {
        guard currentState == .idle else { return }
        flushCurrentDuration()
        currentState = .sleeping
        stateSource = .manual
        stateStartedAt = Date()
        scenarioTitle = PetState.sleeping.defaultTitle
        scenarioSubtitle = NSLocalizedString("sleep.hint", value: "嘘，它在打盹…", comment: "")
        updateOrStartLiveActivity(for: .sleeping)
    }

    // MARK: - 时长上报

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled { flushCurrentDuration() }
            }
        }
    }

    private func flushCurrentDuration() {
        let now = Date()
        let dur = now.timeIntervalSince(stateStartedAt)
        guard dur > 0 else { return }
        achievements.addDuration(dur, for: currentState, at: now)
        stateStartedAt = now
    }

    // MARK: - 宠物解锁

    private func checkPetUnlocks() {
        let newly = profile.checkUnlocks(loyaltySeconds: achievements.metrics.loyaltySeconds,
                                         unlockedAchievementCount: achievements.unlockedIDs.count)
        if !newly.isEmpty {
            newlyUnlockedPets.append(contentsOf: newly)
        }
    }

    public func popNewlyUnlockedPet() -> PetSpecies? {
        guard !newlyUnlockedPets.isEmpty else { return nil }
        return newlyUnlockedPets.removeFirst()
    }

    // MARK: - Live Activity

    /// 统一入口：有活动中的 LA 就更新，没有就新启动一个。
    /// 这是实现“常驻灵动岛”的核心 —— 不再每次都先 end 再 start。
    private func updateOrStartLiveActivity(for state: PetState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityActive = false
            return
        }
        if let existing = Activity<PetActivityAttributes>.activities.first {
            let content = PetActivityContentState(
                state: state,
                title: scenarioTitle,
                subtitle: scenarioSubtitle,
                startedAt: Date(),
                accentHex: state.accentHex
            )
            Task { await existing.update(ActivityContent(state: content, staleDate: nil)) }
            liveActivityActive = true
        } else {
            startLiveActivity(for: state)
        }
    }

    /// 让小猫（重新）登上灵动岛。App 进入前台、或开启常驻开关时调用。
    public func ensureLiveActivity() {
        guard keepOnIsland, ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityActive = false
            return
        }
        // 已有活动 LA：仅在内容过时时刷新一次（例如长时间后台后回到前台）。
        if Activity<PetActivityAttributes>.activities.first != nil {
            liveActivityActive = true
            updateLiveActivity(to: currentState, title: scenarioTitle, subtitle: scenarioSubtitle)
            return
        }
        startLiveActivity(for: currentState)
    }

    private func startLiveActivity(for state: PetState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityActive = false
            return
        }
        // 同一时间只保留一个宠物 Live Activity：先结束残留的旧的。
        for activity in Activity<PetActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        let attrs = PetActivityAttributes(petName: pet.name, species: pet.species.speciesCode)
        let contentState = PetActivityContentState(
            state: state,
            title: scenarioTitle,
            subtitle: scenarioSubtitle,
            startedAt: Date(),
            accentHex: state.accentHex
        )
        do {
            _ = try Activity.request(attributes: attrs,
                                     content: ActivityContent(state: contentState, staleDate: nil),
                                     pushType: nil)
            liveActivityActive = true
        } catch {
            liveActivityActive = false
        }
    }

    private func updateLiveActivity(to state: PetState, title: String, subtitle: String) {
        guard let activity = Activity<PetActivityAttributes>.activities.first else { return }
        let content = PetActivityContentState(
            state: state,
            title: title,
            subtitle: subtitle,
            startedAt: Date(),
            accentHex: state.accentHex
        )
        Task { await activity.update(ActivityContent(state: content, staleDate: nil)) }
    }

    /// 切换“常驻灵动岛”开关。
    public func setKeepOnIsland(_ on: Bool) {
        keepOnIsland = on
        if on {
            ensureLiveActivity()
        } else {
            endLiveActivity()
        }
    }

    /// 续期：iOS 无推送的 Live Activity 默认 8 小时自动结束。
    /// App 在前台时每 15 分钟检查一次，若已被系统结束则重启，保持“一直在岛上”。
    private func startKeepAlive() {
        keepAliveTask?.cancel()
        keepAliveTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15 * 60))
                if Task.isCancelled { break }
                if keepOnIsland, Activity<PetActivityAttributes>.activities.isEmpty {
                    ensureLiveActivity()
                }
            }
        }
    }

    public func endLiveActivity() {
        for activity in Activity<PetActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        liveActivityActive = false
    }
}

public extension PetState {
    /// 默认场景文案。
    var defaultTitle: String {
        switch self {
        case .sleeping:   return NSLocalizedString("title.sleep", value: "打盹中…", comment: "")
        case .idle:       return NSLocalizedString("title.idle", value: "陪你待机", comment: "")
        case .music:      return NSLocalizedString("title.music", value: "正在听歌", comment: "")
        case .working:    return NSLocalizedString("title.work", value: "专注工作中", comment: "")
        case .navigating: return NSLocalizedString("title.nav", value: "正在导航", comment: "")
        case .playing:    return NSLocalizedString("title.play", value: "娱乐时光", comment: "")
        }
    }
}

/// 触感反馈封装。不同状态用不同强度，提升交互质感。
public enum Haptics {
    public static func tap(state: PetState) {
        switch state {
        case .music:      impact(.rigid, 0.4)
        case .playing:    impact(.medium, 0.6)
        case .working:    impact(.soft, 0.5)
        case .navigating: impact(.light, 0.4)
        case .sleeping:   impact(.soft, 0.3)
        case .idle:       break
        }
    }
    public static func light() { impact(.light, 0.3) }
    public static func success() {
        guard defaultsAreEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, _ intensity: CGFloat) {
        guard defaultsAreEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred(intensity: intensity)
    }
    private static var defaultsAreEnabled: Bool {
        UserDefaults.standard.object(forKey: "PocketPet.hapticsEnabled") as? Bool ?? true
    }
}
