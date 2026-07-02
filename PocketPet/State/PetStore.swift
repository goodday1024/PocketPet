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

    /// 当前宠物（绑定到 profile）。
    public var pet: Pet { profile.currentPet }

    /// 空闲多久（无任何场景）后进入打盹。
    private let idleToSleep: TimeInterval = 30
    private var idleTask: Task<Void, Never>?
    private var stateStartedAt: Date = .init()
    private var tickerTask: Task<Void, Never>?

    public init(profile: ProfileStore, achievements: AchievementStore) {
        self.profile = profile
        self.achievements = achievements
        self.stateStartedAt = Date()
        self.scenarioTitle = PetState.idle.defaultTitle
        startTicker()
        resetIdleTimer()
    }

    // MARK: - 状态切换

    /// 进入指定场景状态，并（可选）启动灵动岛展示。
    public func enter(_ state: PetState,
                      title: String = "",
                      subtitle: String = "",
                      presentLiveActivity: Bool = true) {
        flushCurrentDuration()
        currentState = state
        stateStartedAt = Date()
        scenarioTitle = title.isEmpty ? state.defaultTitle : title
        scenarioSubtitle = subtitle
        achievements.collect(state: state)
        Haptics.tap(state: state)

        // 计次类（导航 / 消息）立即 +1
        if state == .navigating { achievements.incrementCount(for: .navigation) }

        if presentLiveActivity {
            startLiveActivity(for: state)
        }
        resetIdleTimer()
        checkPetUnlocks()
    }

    /// 结束当前场景，回到待机；若一段时间无操作则进入打盹。
    public func endScenario() {
        flushCurrentDuration()
        endLiveActivity()
        currentState = .idle
        stateStartedAt = Date()
        scenarioTitle = PetState.idle.defaultTitle
        scenarioSubtitle = ""
        Haptics.light()
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

    private func fallAsleep() {
        guard currentState == .idle else { return }
        flushCurrentDuration()
        currentState = .sleeping
        stateStartedAt = Date()
        scenarioTitle = PetState.sleeping.defaultTitle
        scenarioSubtitle = NSLocalizedString("sleep.hint", value: "嘘，它在打盹…", comment: "")
        updateLiveActivity(to: .sleeping, title: scenarioTitle, subtitle: scenarioSubtitle)
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

    private func startLiveActivity(for state: PetState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityActive = false
            return
        }
        // 同一时间只保留一个宠物 Live Activity：先结束旧的
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
