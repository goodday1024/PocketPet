import Foundation
import Combine

/// 用户档案：管理拥有的宠物、当前选中宠物、是否完成 onboarding。
/// 持久化到 UserDefaults。
@MainActor
public final class ProfileStore: ObservableObject {
    @Published public private(set) var roster: [Pet]
    @Published public var currentPetID: UUID
    @Published public var hasOnboarded: Bool
    /// 当前选中宠物（计算属性）。
    public var currentPet: Pet {
        roster.first { $0.id == currentPetID } ?? roster[0]
    }

    private let defaults = UserDefaults.standard
    private let rosterKey = "PocketPet.roster.v1"
    private let currentKey = "PocketPet.currentPet.v1"
    private let onboardKey = "PocketPet.onboarded.v1"

    public init() {
        let r: [Pet] = ProfileStore.load(defaults: UserDefaults.standard, key: "PocketPet.roster.v1") ??
            [Pet(name: NSLocalizedString("default.pet.name", value: "咪咪", comment: ""), species: .orangeCat)]
        self.roster = r
        let cur: UUID? = ProfileStore.load(defaults: UserDefaults.standard, key: "PocketPet.currentPet.v1")
        self.currentPetID = cur ?? r[0].id
        self.hasOnboarded = UserDefaults.standard.bool(forKey: "PocketPet.onboarded.v1")
    }

    // MARK: - 宠物管理

    /// 切换当前宠物。
    public func switchTo(_ id: UUID) {
        guard roster.contains(where: { $0.id == id }) else { return }
        currentPetID = id
        persist()
    }

    /// 重命名当前宠物。
    public func renameCurrent(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = roster.firstIndex(where: { $0.id == currentPetID }) {
            roster[idx].name = trimmed
            persist()
        }
    }

    /// 解锁并加入新宠物到名册（已存在则忽略）。
    public func addIfNew(_ species: PetSpecies, name: String) -> Pet {
        if let existing = roster.first(where: { $0.species == species }) {
            return existing
        }
        let pet = Pet(name: name, species: species)
        roster.append(pet)
        persist()
        return pet
    }

    /// 是否已拥有该物种。
    public func owns(_ species: PetSpecies) -> Bool {
        roster.contains { $0.species == species }
    }

    /// 检查并解锁满足条件的宠物，返回新解锁的物种列表。
    public func checkUnlocks(loyaltySeconds: Double, unlockedAchievementCount: Int) -> [PetSpecies] {
        var newly: [PetSpecies] = []
        for s in PetSpecies.allCases where !owns(s) {
            if s.isUnlocked(loyaltySeconds: loyaltySeconds,
                            unlockedAchievementCount: unlockedAchievementCount) {
                let name = defaultName(for: s)
                _ = addIfNew(s, name: name)
                newly.append(s)
            }
        }
        return newly
    }

    public func defaultName(for s: PetSpecies) -> String {
        switch s {
        case .orangeCat: return NSLocalizedString("default.pet.name", value: "咪咪", comment: "")
        case .blackCat:  return NSLocalizedString("default.pet.black", value: "小黑", comment: "")
        case .whiteCat:  return NSLocalizedString("default.pet.white", value: "雪球", comment: "")
        }
    }

    public func markOnboarded() {
        hasOnboarded = true
        defaults.set(true, forKey: onboardKey)
    }

    /// 重置全部数据（设置页使用）。
    public func reset() {
        roster = [Pet(name: defaultName(for: .orangeCat), species: .orangeCat)]
        currentPetID = roster[0].id
        hasOnboarded = false
        defaults.removeObject(forKey: rosterKey)
        defaults.removeObject(forKey: currentKey)
        defaults.removeObject(forKey: onboardKey)
    }

    // MARK: - 持久化

    private func persist() {
        if let data = try? JSONEncoder().encode(roster) { defaults.set(data, forKey: rosterKey) }
        if let data = try? JSONEncoder().encode(currentPetID) { defaults.set(data, forKey: currentKey) }
    }

    private static func load<T: Decodable>(defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
