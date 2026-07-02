import SwiftUI

/// 成就页：按分类分组展示，含进度条与解锁状态。
struct AchievementsView: View {
    @EnvironmentObject var store: PetStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summary
                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                    categorySection(cat)
                }
            }
            .padding()
        }
        .navigationTitle("成就")
    }

    private var summary: some View {
        let total = AchievementCatalog.all.count
        let unlocked = store.achievements.unlockedIDs.count
        return HStack {
            VStack(alignment: .leading) {
                Text("\(unlocked) / \(total)").font(.system(size: 32, weight: .bold))
                Text("已解锁成就").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            CircularProgressView(value: Double(unlocked) / Double(max(total, 1)))
                .frame(width: 64, height: 64)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func categorySection(_ cat: AchievementCategory) -> some View {
        let items = AchievementCatalog.all.filter { $0.category == cat }
        return VStack(alignment: .leading, spacing: 10) {
            Text(cat.title).font(.headline)
            ForEach(items) { a in
                achievementRow(a)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func achievementRow(_ a: Achievement) -> some View {
        let unlocked = store.achievements.isUnlocked(a)
        let progress = store.achievements.progress(for: a)
        return HStack(spacing: 12) {
            Text(a.icon).font(.title2)
                .frame(width: 40, height: 40)
                .background(unlocked ? Color(hex: a.accentHex()) : Color.gray.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 10))
                .opacity(unlocked ? 1 : 0.6)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(a.title).font(.subheadline).bold()
                    Text(a.tier.emoji).font(.caption)
                    Spacer()
                    if unlocked {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    }
                }
                Text(a.detail).font(.caption).foregroundStyle(.secondary)
                if !unlocked {
                    ProgressView(value: progress)
                        .tint(Color(hex: a.accentHex()))
                }
            }
        }
    }
}

private extension Achievement {
    func accentHex() -> String {
        switch tier {
        case .bronze: return "#C19A6B"
        case .silver: return "#C0C0C0"
        case .gold:   return "#FFD23F"
        }
    }
}

struct CircularProgressView: View {
    let value: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 6)
            Circle().trim(from: 0, to: value)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))%").font(.caption2).bold()
        }
    }
}
