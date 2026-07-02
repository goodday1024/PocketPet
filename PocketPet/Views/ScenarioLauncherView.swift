import SwiftUI

/// 场景启动器：用户主动触发各种场景，宠物随之切换状态并登上灵动岛。
/// 真机使用时，这些场景也可由系统事件（耳机播放 / 导航 App 唤起）自动触发。
struct ScenarioLauncherView: View {
    @EnvironmentObject var store: PetStore
    @State private var destName = "公司"
    @State private var timerMinutes: Double = 25
    @State private var remainingSeconds: Int = 0
    @State private var countdown: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home.scenario").font(.headline)

            // 听歌：自动检测（说明 + 手动覆盖入口）
            autoMusicCard

            // 计时器工作（手动）
            scenarioCard(.working, manual: true) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("home.duration").font(.caption)
                        Slider(value: $timerMinutes, in: 5...120, step: 5)
                        Text("\(Int(timerMinutes)) m").font(.caption).monospacedDigit()
                    }
                    HStack {
                        Button("home.startFocus") { startTimer() }.buttonStyle(.borderedProminent)
                        if remainingSeconds > 0 {
                            Text(String(format: NSLocalizedString("home.remaining", value: "剩余 %@", comment: ""),
                                        formatCountdown(remainingSeconds)))
                                .font(.callout).monospacedDigit()
                        }
                        Spacer()
                        Button(NSLocalizedString("common.end", value: "结束", comment: "")) { endTimer() }.buttonStyle(.bordered)
                    }
                }
            }

            // 导航（手动）
            scenarioCard(.navigating, manual: true) {
                HStack {
                    TextField("home.destination", text: $destName)
                        .textFieldStyle(.roundedBorder)
                    Button("home.go") {
                        store.enter(.navigating,
                                    title: String(format: NSLocalizedString("fmt.heading", value: "前往: %@", comment: ""), destName),
                                    subtitle: NSLocalizedString("nav.hint", value: "拿着地图找路中…", comment: ""))
                    }.buttonStyle(.borderedProminent)
                }
            }

            // 娱乐（手动）
            scenarioCard(.playing, manual: true) {
                HStack {
                    Button("home.startPlay") {
                        store.enter(.playing, title: NSLocalizedString("title.play", value: "娱乐时光", comment: ""),
                                    subtitle: NSLocalizedString("play.hint", value: "打游戏 / 聊天中", comment: ""))
                    }.buttonStyle(.borderedProminent)
                    Button("home.sendMsg") {
                        if store.currentState != .playing {
                            store.enter(.playing, title: NSLocalizedString("title.play", value: "娱乐时光", comment: ""),
                                        subtitle: NSLocalizedString("play.hint", value: "打游戏 / 聊天中", comment: ""))
                        }
                        store.sendMessage()
                    }.buttonStyle(.bordered)
                }
            }

            Button(role: .destructive) {
                endTimer()
                store.endScenario()
            } label: {
                Label("home.endAll", systemImage: "stop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    /// 听歌：说明由系统自动检测，并提供手动测试入口。
    private var autoMusicCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(PetState.music.emoji).font(.title3)
                Text(PetState.music.displayName).font(.subheadline).bold()
                Spacer()
                Label("auto.badge", systemImage: "waveform")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }
            if store.detector.isPlayingMusic {
                Text(String(format: NSLocalizedString("auto.music.detecting", value: "检测到播放：%@", comment: ""),
                            store.detector.nowPlayingTitle ?? NSLocalizedString("auto.music.unknown", value: "未知曲目", comment: "")))
                    .font(.caption).foregroundStyle(.green)
            } else {
                Text("auto.music.idle").font(.caption).foregroundStyle(.secondary)
            }
            Text("auto.music.hint").font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func scenarioCard<S: View>(_ state: PetState, manual: Bool = false, @ViewBuilder content: () -> S) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(state.emoji).font(.title3)
                Text(state.displayName).font(.subheadline).bold()
                if manual {
                    Label("manual.badge", systemImage: "hand.tap")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                }
                Spacer()
                if store.currentState == state {
                    Text("home.inProgress").font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background((Color(hex: state.accentHex) ?? .orange).opacity(0.2), in: Capsule())
                }
            }
            content()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 计时器

    private func startTimer() {
        countdown?.invalidate()
        remainingSeconds = Int(timerMinutes * 60)
        store.enter(.working,
                    title: String(format: NSLocalizedString("fmt.focus", value: "专注 %d 分钟", comment: ""), Int(timerMinutes)),
                    subtitle: String(format: NSLocalizedString("home.remaining", value: "剩余 %@", comment: ""),
                                     formatCountdown(remainingSeconds)))
        countdown = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                remainingSeconds -= 1
                if remainingSeconds <= 0 {
                    endTimer()
                    Haptics.success()
                } else {
                    store.scenarioSubtitle = String(format: NSLocalizedString("home.remaining", value: "剩余 %@", comment: ""),
                                                    formatCountdown(remainingSeconds))
                }
            }
        }
    }

    private func endTimer() {
        countdown?.invalidate()
        countdown = nil
        remainingSeconds = 0
    }

    private func formatCountdown(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

private extension PetState {
    var accentColor: Color {
        Color(hex: accentHex) ?? .orange
    }
}
