import Foundation

/// 萌宠当前所处的场景状态。每个状态对应一组动画帧 + 一种灵动岛展示形态。
/// 后续新增宠物时复用同一套状态机，仅替换 PixelSprite 数据即可。
public enum PetState: String, CaseIterable, Codable, Sendable, Hashable {
    /// 无任何操作一段时间后 -> 打盹
    case sleeping
    /// 待机（刚启动 / 用户在场但未触发场景）
    case idle
    /// 播放音乐时跟随音乐摇摆
    case music
    /// 打开计时器并计时 -> 工作状态
    case working
    /// 导航中 -> 拿着地图找路
    case navigating
    /// 发信息 / 打游戏 -> 娱乐状态
    case playing

    public var displayName: String {
        switch self {
        case .sleeping:    return "打盹中"
        case .idle:        return "待机中"
        case .music:       return "听歌摇摆"
        case .working:     return "专注工作"
        case .navigating:  return "看图找路"
        case .playing:     return "娱乐时光"
        }
    }

    public var emoji: String {
        switch self {
        case .sleeping:    return "💤"
        case .idle:        return "🐾"
        case .music:       return "🎵"
        case .working:     return "⏱"
        case .navigating:  return "🗺"
        case .playing:     return "🎮"
        }
    }

    /// 默认 1 帧间隔（秒）。摇摆 / 工作等状态更快，打盹更慢。
    public var frameInterval: TimeInterval {
        switch self {
        case .sleeping:   return 0.55
        case .idle:       return 0.45
        case .music:      return 0.18
        case .working:    return 0.30
        case .navigating: return 0.35
        case .playing:    return 0.22
        }
    }

    /// 对应的成就分类，用于统计时长 / 次数。
    public var achievementCategory: AchievementCategory? {
        switch self {
        case .music:       return .listening
        case .working:     return .working
        case .navigating:  return .navigation
        case .playing:     return .gaming
        case .sleeping:    return nil
        case .idle:        return nil
        }
    }
}

/// 成就分类（与 PetState 关联，但也可独立统计，例如消息条数）。
public enum AchievementCategory: String, CaseIterable, Codable, Sendable {
    case listening    // 听歌
    case gaming       // 游戏
    case navigation   // 导航
    case working      // 工作（计时器）
    case messaging    // 发消息
    case social       // 社交
    case collection   // 全状态收集
    case loyalty      // 陪伴总时长

    public var title: String {
        switch self {
        case .listening:  return "乐迷"
        case .gaming:     return "游戏达人"
        case .navigation: return "路痴救星"
        case .working:    return "工作狂"
        case .messaging:  return "社交蝴蝶"
        case .social:     return "人气王"
        case .collection: return "全状态图鉴"
        case .loyalty:    return "忠实陪伴"
        }
    }
}
