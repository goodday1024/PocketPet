import SwiftUI

/// 首次启动引导：介绍宠物玩法，并让用户为第一只猫命名。
struct OnboardingView: View {
    @EnvironmentObject var store: PetStore
    @Binding var isPresented: Bool
    @State private var page = 0
    @State private var petName = ""

    var body: some View {
        VStack {
            TabView(selection: $page) {
                introPage.tag(0)
                statesPage.tag(1)
                achievementsPage.tag(2)
                namePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            buttonBar
        }
        .background(backgroundGradient)
    }

    private var introPage: some View {
        VStack(spacing: 20) {
            Spacer()
            PixelPetSceneView(state: .idle, species: "cat", pixelSize: 11)
                .scaleEffect(1.2)
            Text("PocketPet").font(.largeTitle).bold()
            Text("onboard.intro.subtitle")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)
            Spacer()
        }
    }

    private var statesPage: some View {
        VStack(spacing: 14) {
            Text("onboard.states.title").font(.title2).bold()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(PetState.allCases) { s in
                    VStack(spacing: 6) {
                        Text(s.emoji).font(.title)
                        Text(s.displayName).font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            Text("onboard.states.hint").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var achievementsPage: some View {
        VStack(spacing: 16) {
            Text("onboard.ach.title").font(.title2).bold()
            VStack(alignment: .leading, spacing: 12) {
                ForEach([("🎧", "听歌时长"), ("🎮", "游戏时长"), ("🗺", "导航次数"),
                         ("⏱", "专注工作"), ("💬", "发送消息"), ("✨", "全状态图鉴")], id: \.1) { item in
                    HStack {
                        Text(item.0).font(.title3)
                        Text(item.1)
                        Spacer()
                        Image(systemName: "lock.fill").foregroundStyle(.secondary).font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            Text("onboard.ach.hint").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            Spacer()
        }
    }

    private var namePage: some View {
        VStack(spacing: 20) {
            Spacer()
            PixelPetSceneView(state: .music, species: "cat", pixelSize: 10)
            Text("onboard.name.title").font(.title2).bold()
            TextField(NSLocalizedString("onboard.name.placeholder", value: "给你的小猫起个名字", comment: ""),
                      text: $petName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .onAppear {
                    if petName.isEmpty { petName = store.profile.defaultName(for: .orangeCat) }
                }
            Spacer()
        }
    }

    private var buttonBar: some View {
        HStack {
            if page > 0 {
                Button("onboard.prev") { page -= 1 }.buttonStyle(.bordered)
            }
            Spacer()
            if page < 3 {
                Button("onboard.next") {
                    withAnimation { page += 1 }
                }.buttonStyle(.borderedProminent)
            } else {
                Button("onboard.start") {
                    if !petName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.profile.renameCurrent(petName)
                    }
                    store.profile.markOnboarded()
                    isPresented = false
                }.buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.10)],
                       startPoint: .top, endPoint: .bottom).ignoresSafeArea()
    }
}

extension PetState: Identifiable {
    public var id: String { rawValue }
}
