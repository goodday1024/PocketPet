import SwiftUI

/// 主页：展示宠物 + 当前状态 + 场景启动器 + 简要成就。
struct HomeView: View {
    @EnvironmentObject var store: PetStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                petStage
                ScenarioLauncherView()
                quickStats
            }
            .padding()
        }
        .background(backgroundGradient)
        .navigationTitle("PocketPet")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.pet.name).font(.title2).bold()
                Text(store.pet.species.displayName + " · " + store.currentState.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: store.liveActivityActive ? "circle.fill" : "circle")
                    .foregroundStyle(store.liveActivityActive ? .green : .secondary)
                Text("灵动岛").font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var petStage: some View {
        VStack(spacing: 8) {
            PixelPetSceneView(state: store.currentState,
                              species: store.pet.species.speciesCode,
                              pixelSize: 12)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .id(store.currentState)
            Text(store.scenarioTitle.isEmpty ? store.currentState.defaultTitle : store.scenarioTitle)
                .font(.headline)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: store.scenarioTitle)
            if !store.scenarioSubtitle.isEmpty {
                Text(store.scenarioSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(duration: 0.4), value: store.currentState)
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatChip(icon: "🎧", value: formatTime(store.achievements.metrics.listeningSeconds), label: "home.listening")
            StatChip(icon: "🎮", value: formatTime(store.achievements.metrics.gamingSeconds), label: "home.playing")
            StatChip(icon: "🗺", value: "\(store.achievements.metrics.navigationCount)", label: "home.nav")
            StatChip(icon: "⏱", value: formatTime(store.achievements.metrics.workingSeconds), label: "home.work")
        }
        .padding(.top, 4)
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.08)],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }

    private func formatTime(_ s: Double) -> String {
        let m = Int(s) / 60
        if m >= 60 { return "\(m / 60)h\(m % 60)m" }
        return "\(m)m"
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.title3)
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
