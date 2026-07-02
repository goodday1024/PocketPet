import Foundation
import Combine

/// 统计指标容器，使用 UserDefaults 持久化。
public struct PetMetrics: Codable, Hashable {
    public var listeningSeconds: Double = 0
    public var gamingSeconds: Double = 0
    public var workingSeconds: Double = 0
    public var navigationCount: Int = 0
    public var messagingCount: Int = 0
    public var loyaltySeconds: Double = 0
    public var lateNightSeconds: Double = 0
    public var earlyBirdSeconds: Double = 0
    public var collectedStates: Set<String> = []   // PetState rawValues
    /// 每日按状态累计的秒数，key 为 "yyyy-MM-dd"。
    public var dailyHistory: [String: [String: Double]] = [:]
    /// 连续陪伴天数（最近一次活跃日往前数）。
    public var currentStreak: Int = 0
    /// 历史最长连续天数。
    public var longestStreak: Int = 0
    /// 最近一次活跃日期 "yyyy-MM-dd"。
    public var lastActiveDay: String?

    public var statesCollectedCount: Int { collectedStates.count }

    public func value(for key: Achievement.MetricKey) -> Double {
        switch key {
        case .listeningSeconds:       return listeningSeconds
        case .gamingSeconds:          return gamingSeconds
        case .workingSeconds:         return workingSeconds
        case .navigationCount:        return Double(navigationCount)
        case .messagingCount:         return Double(messagingCount)
        case .statesCollectedCount:   return Double(statesCollectedCount)
        case .loyaltySeconds:         return loyaltySeconds
        case .lateNightSeconds:       return lateNightSeconds
        case .earlyBirdSeconds:       return earlyBirdSeconds
        case .streakDays:             return Double(currentStreak)
        }
    }
}

/// 成就存储：维护 metrics、计算已解锁成就、记录新解锁。
@MainActor
public final class AchievementStore: ObservableObject {
    @Published public private(set) var metrics: PetMetrics
    @Published public private(set) var unlockedIDs: Set<String>
    @Published public private(set) var newlyUnlocked: [Achievement] = []   // 待展示的弹窗队列

    private let defaults = UserDefaults.standard
    private let metricsKey = "PocketPet.metrics.v1"
    private let unlockedKey = "PocketPet.unlocked.v1"

    public init() {
        self.metrics = AchievementStore.load(defaults: UserDefaults.standard, key: metricsKey) ?? PetMetrics()
        self.unlockedIDs = AchievementStore.load(defaults: UserDefaults.standard, key: unlockedKey) ?? []
    }

    // MARK: - 上报

    /// 累加某状态的持续时长。
    public func addDuration(_ seconds: Double, for state: PetState, at date: Date = Date()) {
        guard seconds > 0 else { return }
        metrics.loyaltySeconds += seconds
        // 时段彩蛋
        let hour = Calendar.current.component(.hour, from: date)
        if (0..<5).contains(hour) { metrics.lateNightSeconds += seconds }
        if (5..<8).contains(hour) { metrics.earlyBirdSeconds += seconds }
        switch state {
        case .music:      metrics.listeningSeconds += seconds
        case .playing:    metrics.gamingSeconds += seconds
        case .working:    metrics.workingSeconds += seconds
        case .navigating: break // 导航按次数计
        case .sleeping, .idle: break
        }
        recordDaily(state: state, seconds: seconds, date: date)
        bumpStreak(date: date)
        collect(state: state)
        persist()
        recompute()
    }

    /// 记录每日每状态秒数（用于统计详情页柱状图）。
    private func recordDaily(state: PetState, seconds: Double, date: Date) {
        let key = Self.dayKey(date)
        var day = metrics.dailyHistory[key] ?? [:]
        day[state.rawValue, default: 0] += seconds
        metrics.dailyHistory[key] = day
        // 仅保留最近 30 天，避免无限增长。
        if metrics.dailyHistory.count > 30 {
            let cutoff = Self.dayKey(Calendar.current.date(byAdding: .day, value: -30, to: date) ?? date)
            metrics.dailyHistory = metrics.dailyHistory.filter { $0.key >= cutoff }
        }
    }

    /// 更新连续打卡。
    private func bumpStreak(date: Date) {
        let today = Self.dayKey(date)
        guard metrics.lastActiveDay != today else { return } // 当天已计
        let yesterday = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date)
        if metrics.lastActiveDay == yesterday {
            metrics.currentStreak += 1
        } else if metrics.lastActiveDay == nil {
            metrics.currentStreak = 1
        } else {
            metrics.currentStreak = 1 // 断了，重新计
        }
        metrics.lastActiveDay = today
        metrics.longestStreak = max(metrics.longestStreak, metrics.currentStreak)
    }

    /// 取最近 N 天的每日汇总（用于图表）。
    public func recentDays(_ n: Int) -> [(day: String, total: Double, byState: [PetState: Double])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var out: [(String, Double, [PetState: Double])] = []
        for i in stride(from: n - 1, through: 0, by: -1) {
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            let key = Self.dayKey(d)
            let day = metrics.dailyHistory[key] ?? [:]
            var byState: [PetState: Double] = [:]
            var total: Double = 0
            for (s, v) in day {
                if let ps = PetState(rawValue: s) { byState[ps] = v; total += v }
            }
            out.append((key, total, byState))
        }
        return out
    }

    private static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// 累加次数（导航 / 消息）。
    public func incrementCount(for category: AchievementCategory) {
        switch category {
        case .navigation: metrics.navigationCount += 1
        case .messaging:  metrics.messagingCount += 1
        default: break
        }
        persist()
        recompute()
    }

    /// 记录已收集过的状态。
    public func collect(state: PetState) {
        metrics.collectedStates.insert(state.rawValue)
        persist()
        recompute()
    }

    // MARK: - 解锁计算

    public func isUnlocked(_ a: Achievement) -> Bool {
        metrics.value(for: a.metricKey) >= a.threshold
    }

    /// 进度 0~1。
    public func progress(for a: Achievement) -> Double {
        let v = metrics.value(for: a.metricKey)
        return min(1, v / a.threshold)
    }

    private func recompute() {
        for a in AchievementCatalog.all where isUnlocked(a) {
            if !unlockedIDs.contains(a.id) {
                unlockedIDs.insert(a.id)
                newlyUnlocked.append(a)
            }
        }
        persist()
    }

    /// 弹窗消费：取出一条新解锁。
    public func popNewlyUnlocked() -> Achievement? {
        guard !newlyUnlocked.isEmpty else { return nil }
        return newlyUnlocked.removeFirst()
    }

    /// 清空全部统计与解锁记录（设置页重置时调用）。
    public func reset() {
        metrics = PetMetrics()
        unlockedIDs = []
        newlyUnlocked = []
        defaults.removeObject(forKey: metricsKey)
        defaults.removeObject(forKey: unlockedKey)
    }

    // MARK: - 持久化

    private func persist() {
        if let data = try? JSONEncoder().encode(metrics) { defaults.set(data, forKey: metricsKey) }
        if let data = try? JSONEncoder().encode(unlockedIDs) { defaults.set(data, forKey: unlockedKey) }
    }

    private static func load<T: Decodable>(defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
