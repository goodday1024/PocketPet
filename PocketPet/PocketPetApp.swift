import SwiftUI

@main
struct PocketPetApp: App {
    @StateObject private var store: PetStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let profile = ProfileStore()
        let achievements = AchievementStore()
        _store = StateObject(wrappedValue: PetStore(profile: profile, achievements: achievements))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(store.profile)
                .environmentObject(store.achievements)
                .onChange(of: scenePhase) { phase in
                    // App 回到前台时，确保小猫仍在灵动岛上（系统可能已结束过期的 LA）。
                    if phase == .active {
                        store.ensureLiveActivity()
                    }
                }
        }
    }
}
