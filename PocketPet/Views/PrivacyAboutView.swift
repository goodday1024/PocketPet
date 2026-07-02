import SwiftUI

/// 隐私政策页。PocketPet 不收集任何个人数据，所有统计仅存于本地。
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("privacy.title").font(.title2).bold()
                Text("privacy.updated").font(.caption).foregroundStyle(.secondary)
                Divider()
                ForEach(privacySections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title).font(.headline)
                        Text(section.body).font(.body).foregroundStyle(.primary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("settings.privacy")
    }

    private struct Section: Identifiable {
        let id = UUID()
        let title: LocalizedStringKey
        let body: LocalizedStringKey
    }

    private var privacySections: [Section] {
        [
            .init(title: "privacy.collect.title", body: "privacy.collect.body"),
            .init(title: "privacy.storage.title", body: "privacy.storage.body"),
            .init(title: "privacy.activity.title", body: "privacy.activity.body"),
            .init(title: "privacy.third.title", body: "privacy.third.body"),
            .init(title: "privacy.children.title", body: "privacy.children.body"),
            .init(title: "privacy.contact.title", body: "privacy.contact.body"),
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
