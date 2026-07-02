import Foundation

/// 单条成就定义。`metricKey` 决定统计哪一项指标，`threshold` 是达成阈值。
public struct Achievement: Codable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var detail: String
    public var category: AchievementCategory
    public var tier: Tier
    public var metricKey: MetricKey
    public var threshold: Double   // 秒数或次数，按 metricKey 解释
    public var icon: String

    public enum Tier: String, Codable, CaseIterable {
        case bronze, silver, gold
        public var label: String { ["bronze": "铜", "silver": "银", "gold": "金"][rawValue]! }
        public var emoji: String { ["bronze": "🥉", "silver": "🥈", "gold": "🥇"][rawValue]! }
    }

    /// 所有可统计的指标。
    public enum MetricKey: String, Codable, CaseIterable {
        case listeningSeconds
        case gamingSeconds
        case workingSeconds
        case navigationCount
        case messagingCount
        case statesCollectedCount
        case loyaltySeconds
        case lateNightSeconds   // 夜猫子：0-5 点使用时长
        case earlyBirdSeconds   // 早起鸟：5-8 点使用时长
    }
}

/// 成就全集。可在此继续扩充。
public enum AchievementCatalog {
    public static let all: [Achievement] = [
        // 乐迷
        .init(id: "listen_b", title: "初听者", detail: "累计听歌 10 分钟", category: .listening, tier: .bronze, metricKey: .listeningSeconds, threshold: 600, icon: "🎧"),
        .init(id: "listen_s", title: "乐迷", detail: "累计听歌 1 小时", category: .listening, tier: .silver, metricKey: .listeningSeconds, threshold: 3600, icon: "🎵"),
        .init(id: "listen_g", title: "音乐发烧友", detail: "累计听歌 10 小时", category: .listening, tier: .gold, metricKey: .listeningSeconds, threshold: 36000, icon: "🎼"),
        // 游戏达人
        .init(id: "game_b", title: "新手玩家", detail: "累计娱乐 10 分钟", category: .gaming, tier: .bronze, metricKey: .gamingSeconds, threshold: 600, icon: "🎮"),
        .init(id: "game_s", title: "游戏达人", detail: "累计娱乐 2 小时", category: .gaming, tier: .silver, metricKey: .gamingSeconds, threshold: 7200, icon: "🕹"),
        .init(id: "game_g", title: "电竞之魂", detail: "累计娱乐 10 小时", category: .gaming, tier: .gold, metricKey: .gamingSeconds, threshold: 36000, icon: "🏆"),
        // 路痴救星（"多少次不知道怎么走"）
        .init(id: "nav_b", title: "初次问路", detail: "使用导航 1 次", category: .navigation, tier: .bronze, metricKey: .navigationCount, threshold: 1, icon: "🗺"),
        .init(id: "nav_s", title: "常在路上", detail: "使用导航 10 次", category: .navigation, tier: .silver, metricKey: .navigationCount, threshold: 10, icon: "🧭"),
        .init(id: "nav_g", title: "路痴救星", detail: "使用导航 100 次", category: .navigation, tier: .gold, metricKey: .navigationCount, threshold: 100, icon: "🌍"),
        // 工作狂
        .init(id: "work_b", title: "番茄一颗", detail: "专注工作 25 分钟", category: .working, tier: .bronze, metricKey: .workingSeconds, threshold: 1500, icon: "⏱"),
        .init(id: "work_s", title: "深度专注", detail: "专注工作 2 小时", category: .working, tier: .silver, metricKey: .workingSeconds, threshold: 7200, icon: "📚"),
        .init(id: "work_g", title: "工作狂", detail: "专注工作 10 小时", category: .working, tier: .gold, metricKey: .workingSeconds, threshold: 36000, icon: "💼"),
        // 社交蝴蝶（发消息）
        .init(id: "msg_b", title: "初出茅庐", detail: "发送消息 1 次", category: .messaging, tier: .bronze, metricKey: .messagingCount, threshold: 1, icon: "💬"),
        .init(id: "msg_s", title: "社交蝴蝶", detail: "发送消息 50 次", category: .messaging, tier: .silver, metricKey: .messagingCount, threshold: 50, icon: "🕊"),
        .init(id: "msg_g", title: "人气王", detail: "发送消息 500 次", category: .messaging, tier: .gold, metricKey: .messagingCount, threshold: 500, icon: "👑"),
        // 全状态图鉴
        .init(id: "col_b", title: "状态收集者", detail: "收集 3 种状态", category: .collection, tier: .bronze, metricKey: .statesCollectedCount, threshold: 3, icon: "🍀"),
        .init(id: "col_s", title: "图鉴达人", detail: "收集 5 种状态", category: .collection, tier: .silver, metricKey: .statesCollectedCount, threshold: 5, icon: "📖"),
        .init(id: "col_g", title: "全状态图鉴", detail: "收集全部 6 种状态", category: .collection, tier: .gold, metricKey: .statesCollectedCount, threshold: 6, icon: "✨"),
        // 忠实陪伴（陪伴总时长）
        .init(id: "loy_b", title: "初次陪伴", detail: "陪伴 1 小时", category: .loyalty, tier: .bronze, metricKey: .loyaltySeconds, threshold: 3600, icon: "🐾"),
        .init(id: "loy_s", title: "一日之伴", detail: "陪伴 24 小时", category: .loyalty, tier: .silver, metricKey: .loyaltySeconds, threshold: 86400, icon: "💞"),
        .init(id: "loy_g", title: "忠实陪伴", detail: "陪伴 7 天", category: .loyalty, tier: .gold, metricKey: .loyaltySeconds, threshold: 604800, icon: "🏅"),
        // 彩蛋
        .init(id: "late_b", title: "夜猫子", detail: "0-5 点陪伴 30 分钟", category: .loyalty, tier: .bronze, metricKey: .lateNightSeconds, threshold: 1800, icon: "🌙"),
        .init(id: "early_b", title: "早起鸟", detail: "5-8 点陪伴 30 分钟", category: .loyalty, tier: .bronze, metricKey: .earlyBirdSeconds, threshold: 1800, icon: "🌅"),
    ]
}
