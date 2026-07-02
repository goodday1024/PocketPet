import SwiftUI

/// 统计详情页：连续天数、最近 7 天柱状图、各状态总时长分布。
struct StatsDetailView: View {
    @EnvironmentObject var store: PetStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                streakCard
                weekChartCard
                distributionCard
                countsCard
            }
            .padding()
        }
        .navigationTitle("stats.title")
    }

    private var streakCard: some View {
        HStack {
            statBlock(value: "\(store.achievements.metrics.currentStreak)",
                      label: "stats.currentStreak")
            Divider().frame(height: 40)
            statBlock(value: "\(store.achievements.metrics.longestStreak)",
                      label: "stats.longestStreak")
            Divider().frame(height: 40)
            statBlock(value: "\(store.achievements.metrics.statesCollectedCount)/6",
                      label: "stats.states")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statBlock(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).bold().monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weekChartCard: some View {
        let days = store.achievements.recentDays(7)
        let maxV = max(days.map { $0.total }.max() ?? 1, 60)
        return VStack(alignment: .leading, spacing: 12) {
            Text("stats.week").font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days, id: \.day) { d in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 120)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(height: max(4, CGFloat(d.total / maxV) * 120))
                        }
                        Text(shortDay(d.day)).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var distributionCard: some View {
        let m = store.achievements.metrics
        let items: [(String, Double, Color)] = [
            ("🎧", m.listeningSeconds, .yellow),
            ("🎮", m.gamingSeconds, .red),
            ("⏱", m.workingSeconds, .green),
            ("🌙", m.lateNightSeconds, .blue),
            ("🌅", m.earlyBirdSeconds, .orange),
        ]
        let total = max(items.map { $0.1 }.reduce(0, +), 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("stats.distribution").font(.headline)
            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                    Text(formatTime(item.1)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Spacer()
                    ProgressView(value: item.1 / total).tint(item.2).frame(width: 100)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var countsCard: some View {
        let m = store.achievements.metrics
        return HStack(spacing: 12) {
            countChip("🗺", "\(m.navigationCount)", "stats.navCount")
            countChip("💬", "\(m.messagingCount)", "stats.msgCount")
        }
    }

    private func countChip(_ icon: String, _ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title3)
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func shortDay(_ key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return "" }
        let g = DateFormatter()
        g.dateFormat = "E"
        return g.string(from: d)
    }

    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }
}
