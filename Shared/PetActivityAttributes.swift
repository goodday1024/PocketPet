import Foundation
import ActivityKit

/// Live Activity 的静态属性（开始时确定，整个活动期间不变）。
public struct PetActivityAttributes: ActivityAttributes {
    public typealias ContentState = PetActivityContentState

    /// 宠物名（例如 "咪咪"）。
    public var petName: String
    /// 宠物种类标识（"cat" / "dog" ...），决定灵动岛里渲染哪套像素图。
    public var species: String

    public init(petName: String, species: String = "cat") {
        self.petName = petName
        self.species = species
    }
}

/// Live Activity 的动态状态（可随时间更新）。
public struct PetActivityContentState: Codable, Hashable {
    /// 当前场景状态。
    public var state: PetState
    /// 主标题，例如 "正在听: Shape of You" / "前往: 公司"。
    public var title: String
    /// 副标题，例如歌手 / 剩余时间。
    public var subtitle: String
    /// 该状态开始的时间戳，用于成就统计与显示已持续时长。
    public var startedAt: Date
    /// 数值进度（0~1），例如计时器进度、歌曲进度。nil 表示不展示。
    public var progress: Double?
    /// 强调色 hex（与状态匹配），灵动岛描边用。
    public var accentHex: String

    public init(state: PetState,
                title: String,
                subtitle: String,
                startedAt: Date,
                progress: Double? = nil,
                accentHex: String = "#FF9D3F") {
        self.state = state
        self.title = title
        self.subtitle = subtitle
        self.startedAt = startedAt
        self.progress = progress
        self.accentHex = accentHex
    }
}

public extension PetState {
    /// 每个状态对应的强调色（hex）。
    var accentHex: String {
        switch self {
        case .sleeping:   return "#7FD4FF"
        case .idle:       return "#FF9D3F"
        case .music:      return "#FFD23F"
        case .working:    return "#5FD068"
        case .navigating: return "#C89B6A"
        case .playing:    return "#E74C3C"
        }
    }
}
