import Foundation
import SwiftUI
import ActivityKit
import Combine

/// 宠物与状态总管：维护当前宠物、当前场景状态、灵动岛 Live Activity，
/// 并把各状态持续时间 / 次数上报给 `AchievementStore`。
@MainActor
public final class PetStore: ObservableObject {

    @Published public var pet: Pet
    @Published public var currentState: PetState = .idle
    @Published public var liveActivityActive: Bool = false
    /// 当前场景的展示文案（歌曲名 / 目的地 / 游戏名 …）。
    @Published public var scenarioTitle: String = ""
    @Published public var scenarioSubtitle: String = ""

    public let achievements = AchievementStore()

    /// 空闲多久（无任何场景）后进入打盹。
    private let idleToSleep: TimeInterval = 30
    private var idleTask: Task<Void, Never>?
    private var stateStartedAt: Date = .init()
    private var tickerTask: Task<Void, Never>?

    public init(pet: Pet = Pet(name: "咪咪", species: .orangeCat)) {
        self.pet = pet
        self.stateStartedAt = Date()
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

        // 计次类（导航 / 消息）立即 +1
        if state == .navigating { achievements.incrementCount(for: .navigation) }

        if presentLiveActivity {
            startLiveActivity(for: state)
        }
        resetIdleTimer()
    }

    /// 结束当前场景，回到待机；若一段时间无操作则进入打盹。
    public func endScenario() {
        flushCurrentDuration()
        endLiveActivity()
        currentState = .idle
        stateStartedAt = Date()
        scenarioTitle = PetState.idle.defaultTitle
        scenarioSubtitle = ""
        resetIdleTimer()
    }

    /// 发送一条消息（娱乐状态下的子动作）。
    public func sendMessage() {
        achievements.incrementCount(for: .messaging)
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
        scenarioSubtitle = "嘘，它在打盹…"
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
        // 解锁黑煤球：陪伴满 1 小时
        if pet.species == .orangeCat,
           achievements.metrics.loyaltySeconds >= 3600 {
            // 标记可解锁（UI 层提示），这里不自动切换宠物
        }
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
        case .sleeping:   return "打盹中…"
        case .idle:       return "陪你待机"
        case .music:      return "正在听歌"
        case .working:    return "专注工作中"
        case .navigating: return "正在导航"
        case .playing:    return "娱乐时光"
        }
    }
}
