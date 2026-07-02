import Foundation

/// 已支持的宠物种类。后续推出新萌宠时在此追加，并在 `PixelCat`（或对应 PixelXxx）里提供帧数据。
public enum PetSpecies: String, CaseIterable, Codable, Identifiable {
    case orangeCat    // 橘猫（首发）
    case blackCat     // 黑猫（陪伴满 1 小时解锁）
    case whiteCat     // 白猫（解锁 3 个成就解锁）

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .orangeCat: return NSLocalizedString("pet.orange", value: "橘小咪", comment: "")
        case .blackCat:  return NSLocalizedString("pet.black",  value: "黑煤球", comment: "")
        case .whiteCat:  return NSLocalizedString("pet.white",  value: "雪团子", comment: "")
        }
    }

    /// 传递给像素渲染器的种类标识（决定调色板 / 帧集）。
    public var speciesCode: String {
        switch self {
        case .orangeCat: return "cat"
        case .blackCat:  return "blackCat"
        case .whiteCat:  return "whiteCat"
        }
    }

    public var unlockDescription: String {
        switch self {
        case .orangeCat: return NSLocalizedString("pet.orange.unlock", value: "默认伙伴，陪伴你度过每一段时光。", comment: "")
        case .blackCat:  return NSLocalizedString("pet.black.unlock",  value: "累计陪伴 1 小时后解锁。", comment: "")
        case .whiteCat:  return NSLocalizedString("pet.white.unlock",  value: "解锁 3 项成就后解锁。", comment: "")
        }
    }

    /// 是否默认解锁。
    public var isDefault: Bool {
        switch self {
        case .orangeCat: return true
        case .blackCat, .whiteCat: return false
        }
    }

    /// 解锁条件检查。
    public func isUnlocked(loyaltySeconds: Double, unlockedAchievementCount: Int) -> Bool {
        switch self {
        case .orangeCat: return true
        case .blackCat:  return loyaltySeconds >= 3600
        case .whiteCat:  return unlockedAchievementCount >= 3
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
