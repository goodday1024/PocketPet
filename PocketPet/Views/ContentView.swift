import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PetStore
    @State private var toast: Achievement?

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("萌宠", systemImage: "pawprint.fill") }
            NavigationStack { AchievementsView() }
                .tabItem { Label("成就", systemImage: "rosette") }
        }
        .tint(.orange)
        .overlay(alignment: .top) {
            if let t = toast { AchievementToast(achievement: t) }
        }
        .task { pollUnlocked() }
    }

    /// 轮询新解锁的成就并弹出提示。
    private func pollUnlocked() async {
        while !Task.isCancelled {
            if toast == nil, let a = store.achievements.popNewlyUnlocked() {
                toast = a
                try? await Task.sleep(for: .seconds(3))
                toast = nil
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
                Text("🏆 解锁成就").font(.caption).foregroundStyle(.secondary)
                Text(achievement.title).font(.subheadline).bold()
            }
            Spacer()
            Text(achievement.tier.emoji).font(.title3)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .shadow(radius: 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
