import SwiftUI

@main
struct PocketPetApp: App {
    @StateObject private var store = PetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
