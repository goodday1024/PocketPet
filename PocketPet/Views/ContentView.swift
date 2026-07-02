import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PetStore
    @State private var achievementToast: Achievement?
    @State private var petToast: PetSpecies?
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            TabView {
                NavigationStack { HomeView() }
                    .tabItem { Label("tab.home", systemImage: "pawprint.fill") }
                NavigationStack { AchievementsView() }
                    .tabItem { Label("tab.achievements", systemImage: "rosette") }
                NavigationStack { StatsDetailView() }
                    .tabItem { Label("tab.stats", systemImage: "chart.bar.fill") }
                NavigationStack { SettingsView() }
                    .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
            }
            .tint(.orange)

            VStack {
                if let t = achievementToast { AchievementToast(achievement: t) }
                if let p = petToast { PetUnlockToast(species: p) }
            }
            .padding(.top, 8)
            .animation(.spring(duration: 0.4), value: achievementToast)
            .animation(.spring(duration: 0.4), value: petToast)
        }
        .task { await pollUnlocked() }
        .task { await pollPetUnlocks() }
        .onAppear {
            if !store.profile.hasOnboarded { showOnboarding = true }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .environmentObject(store)
        }
    }

    /// 轮询新解锁的成就并弹出提示。
    private func pollUnlocked() async {
        while !Task.isCancelled {
            if achievementToast == nil, let a = store.achievements.popNewlyUnlocked() {
                Haptics.success()
                achievementToast = a
                try? await Task.sleep(for: .seconds(3))
                achievementToast = nil
            } else {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// 轮询新解锁的宠物并弹出提示。
    private func pollPetUnlocks() async {
        while !Task.isCancelled {
            if petToast == nil, let s = store.popNewlyUnlockedPet() {
                Haptics.success()
                petToast = s
                try? await Task.sleep(for: .seconds(3.5))
                petToast = nil
            } else {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

struct AchievementToast: View {
    let achievement: Achievement
    var body: some View {
        HStack(spacing: 10) {
            Text(achievement.icon).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("toast.ach.unlocked").font(.caption).foregroundStyle(.secondary)
                Text(achievement.title).font(.subheadline).bold()
            }
            Spacer()
            Text(achievement.tier.emoji).font(.title3)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .shadow(radius: 8)
    }
}

struct PetUnlockToast: View {
    let species: PetSpecies
    var body: some View {
        HStack(spacing: 12) {
            PixelPetSceneView(state: .idle, species: species.speciesCode, pixelSize: 3)
                .frame(width: 40, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("toast.pet.unlocked").font(.caption).foregroundStyle(.secondary)
                Text(species.displayName).font(.subheadline).bold()
            }
            Spacer()
            Text("🎉").font(.title3)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .shadow(radius: 8)
    }
}
