import SwiftUI

/// 设置页：宠物切换 / 重命名、触感开关、关于、隐私、重置。
struct SettingsView: View {
    @EnvironmentObject var store: PetStore
    @State private var renameText = ""
    @State private var showRename = false
    @State private var showResetConfirm = false
    @AppStorage("PocketPet.hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        Form {
            petSection
            experienceSection
            aboutSection
            resetSection
        }
        .navigationTitle("tab.settings")
        .sheet(isPresented: $showRename) {
            renameSheet
        }
        .confirmationDialog(NSLocalizedString("settings.reset.confirm.title", value: "确认重置", comment: ""),
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button(NSLocalizedString("settings.reset.confirm.confirm", value: "重置", comment: ""), role: .destructive) {
                performReset()
            }
            Button(NSLocalizedString("settings.reset.confirm.cancel", value: "取消", comment: ""), role: .cancel) {}
        } message: {
            Text("settings.reset.confirm.body")
        }
    }

    private var renameSheet: some View {
        NavigationStack {
            Form {
                TextField(NSLocalizedString("settings.rename.title", value: "重命名宠物", comment: ""),
                          text: $renameText)
            }
            .navigationTitle("settings.rename.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("settings.rename.cancel") { showRename = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.rename.save") {
                        store.profile.renameCurrent(renameText)
                        if store.liveActivityActive {
                            store.switchPet(to: store.pet.id)
                        }
                        showRename = false
                    }
                }
            }
        }
    }

    private func performReset() {
        store.endLiveActivity()
        store.achievements.reset()
        store.profile.reset()
    }

    private var petSection: some View {
        Section("settings.pet") {
            NavigationLink {
                PetPickerView()
            } label: {
                HStack {
                    PixelPetSceneView(state: .idle, species: store.pet.species.speciesCode, pixelSize: 3)
                        .frame(width: 36, height: 32)
                    VStack(alignment: .leading) {
                        Text(store.pet.name).font(.body)
                        Text(store.pet.species.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("settings.switch").font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("settings.rename") {
                renameText = store.pet.name
                showRename = true
            }
        }
    }

    private var experienceSection: some View {
        Section {
            Toggle("settings.autoDetect", isOn: Binding(
                get: { store.detector.autoDetectionEnabled },
                set: { store.detector.autoDetectionEnabled = $0 }
            ))
            Toggle("settings.keepIsland", isOn: Binding(
                get: { store.keepOnIsland },
                set: { store.setKeepOnIsland($0) }
            ))
            Toggle("settings.haptics", isOn: $hapticsEnabled)
            HStack {
                Text("settings.streak")
                Spacer()
                Text("\(store.achievements.metrics.currentStreak) \(NSLocalizedString("settings.days", value: "天", comment: ""))")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("settings.loyalty")
                Spacer()
                Text(formatTime(store.achievements.metrics.loyaltySeconds))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("settings.experience")
        } footer: {
            Text("settings.autoDetect.hint")
                .font(.caption2)
        }
    }

    private var aboutSection: some View {
        Section("settings.about") {
            NavigationLink("settings.privacy") { PrivacyView() }
            NavigationLink("settings.aboutApp") { AboutView() }
            Link("settings.github",
                 destination: URL(string: "https://github.com/goodday1024/PocketPet")!)
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Text("settings.reset").foregroundStyle(.red)
            }
        }
    }

    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }
}

/// 宠物选择页：展示已拥有与未解锁的宠物。
struct PetPickerView: View {
    @EnvironmentObject var store: PetStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(PetSpecies.allCases) { species in
                    let owned = store.profile.owns(species)
                    let isCurrent = store.pet.species == species
                    speciesRow(species, owned: owned, isCurrent: isCurrent)
                }
            }
            .padding()
        }
        .navigationTitle("settings.pet")
    }

    private func speciesRow(_ species: PetSpecies, owned: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            PixelPetSceneView(state: .idle, species: species.speciesCode, pixelSize: 4)
                .frame(width: 70, height: 60)
                .opacity(owned ? 1 : 0.4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(species.displayName).font(.headline)
                    if isCurrent {
                        Text("settings.using")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2), in: Capsule())
                    }
                }
                Text(species.unlockDescription).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if owned {
                if !isCurrent {
                    Button("settings.use") {
                        if let pet = store.profile.roster.first(where: { $0.species == species }) {
                            store.switchPet(to: pet.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
