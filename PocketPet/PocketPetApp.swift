import SwiftUI

@main
struct PocketPetApp: App {
    @StateObject private var store: PetStore

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
        }
    }
}
