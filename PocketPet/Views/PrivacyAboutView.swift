import SwiftUI

/// 隐私政策页。PocketPet 不收集任何个人数据，所有统计仅存于本地。
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("privacy.title").font(.title2).bold()
                Text("privacy.updated").font(.caption).foregroundStyle(.secondary)
                Divider()
                ForEach(privacySections, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.0).font(.headline)
                        Text(section.1).font(.body).foregroundStyle(.primary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("settings.privacy")
    }

    private var privacySections: [(LocalizedStringKey, LocalizedStringKey)] {
        [
            ("privacy.collect.title", "privacy.collect.body"),
            ("privacy.storage.title", "privacy.storage.body"),
            ("privacy.activity.title", "privacy.activity.body"),
            ("privacy.third.title", "privacy.third.body"),
            ("privacy.children.title", "privacy.children.body"),
            ("privacy.contact.title", "privacy.contact.body"),
        ]
    }
}

/// 关于页：版本、简介、致谢。
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PixelPetSceneView(state: .idle, species: "cat", pixelSize: 5)
                    .frame(width: 96, height: 84)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                    .shadow(radius: 6)
                Text("PocketPet").font(.title).bold()
                Text(versionText()).font(.caption).foregroundStyle(.secondary)
                Text("about.desc").font(.body).multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("about.credits").font(.headline)
                    Text("about.credits.body").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("settings.aboutApp")
    }

    private func versionText() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }
}
