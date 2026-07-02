import Foundation

/// 已支持的宠物种类。后续推出新萌宠时在此追加，并在 `PixelCat`（或对应 PixelXxx）里提供帧数据。
public enum PetSpecies: String, CaseIterable, Codable, Identifiable {
    case orangeCat    // 橘猫（首发）
    case blackCat     // 黑猫（预告，复用猫骨架 + 深色调色板）

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .orangeCat: return "橘小咪"
        case .blackCat:  return "黑煤球"
        }
    }

    public var speciesCode: String {
        switch self {
        case .orangeCat: return "cat"
        case .blackCat:  return "blackCat"
        }
    }

    public var unlockDescription: String {
        switch self {
        case .orangeCat: return "默认伙伴，陪伴你度过每一段时光。"
        case .blackCat:  return "累计陪伴 1 小时后解锁。"
        }
    }

    /// 是否默认解锁。
    public var isDefault: Bool {
        switch self {
        case .orangeCat: return true
        case .blackCat:  return false
        }
    }
}

/// 一只玩家的萌宠实例。
public struct Pet: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var species: PetSpecies

    public init(id: UUID = UUID(), name: String, species: PetSpecies) {
        self.id = id
        self.name = name
        self.species = species
    }
}
