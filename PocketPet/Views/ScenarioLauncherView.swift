import SwiftUI

/// 场景启动器：用户主动触发各种场景，宠物随之切换状态并登上灵动岛。
/// 真机使用时，这些场景也可由系统事件（耳机播放 / 导航 App 唤起）自动触发。
struct ScenarioLauncherView: View {
    @EnvironmentObject var store: PetStore
    @State private var songName = "Shape of You"
    @State private var destName = "公司"
    @State private var timerMinutes: Double = 25
    @State private var remainingSeconds: Int = 0
    @State private var countdown: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("场景触发").font(.headline)

            // 听歌
            scenarioCard(.music) {
                HStack {
                    TextField("歌曲名", text: $songName)
                        .textFieldStyle(.roundedBorder)
                    Button("开始摇摆") {
                        store.enter(.music, title: "正在听: \(songName)",
                                    subtitle: "跟随节奏摇摆")
                    }.buttonStyle(.borderedProminent)
                }
            }

            // 计时器工作
            scenarioCard(.working) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("时长").font(.caption)
                        Slider(value: $timerMinutes, in: 5...120, step: 5)
                        Text("\(Int(timerMinutes)) 分").font(.caption).monospacedDigit()
                    }
                    HStack {
                        Button("开始专注") { startTimer() }.buttonStyle(.borderedProminent)
                        if remainingSeconds > 0 {
                            Text("剩余 \(formatCountdown(remainingSeconds))")
                                .font(.callout).monospacedDigit()
                        }
                        Spacer()
                        Button("结束") { endTimer() }.buttonStyle(.bordered)
                    }
                }
            }

            // 导航
            scenarioCard(.navigating) {
                HStack {
                    TextField("目的地", text: $destName)
                        .textFieldStyle(.roundedBorder)
                    Button("出发") {
                        store.enter(.navigating, title: "前往: \(destName)",
                                    subtitle: "拿着地图找路中…")
                    }.buttonStyle(.borderedProminent)
                }
            }

            // 娱乐（游戏 / 发消息）
            scenarioCard(.playing) {
                HStack {
                    Button("开始娱乐") {
                        store.enter(.playing, title: "娱乐时光",
                                    subtitle: "打游戏 / 聊天中")
                    }.buttonStyle(.borderedProminent)
                    Button("发条消息") {
                        if store.currentState != .playing {
                            store.enter(.playing, title: "娱乐时光", subtitle: "聊天中")
                        }
                        store.sendMessage()
                    }.buttonStyle(.bordered)
                }
            }

            Button(role: .destructive) {
                endTimer()
                store.endScenario()
            } label: {
                Label("结束所有场景，回待机", systemImage: "stop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func scenarioCard<S: View>(_ state: PetState, @ViewBuilder content: () -> S) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(state.emoji).font(.title3)
                Text(state.displayName).font(.subheadline).bold()
                Spacer()
                if store.currentState == state {
                    Text("进行中").font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(state.accentColor.opacity(0.2), in: Capsule())
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
        store.enter(.working, title: "专注 \(Int(timerMinutes)) 分钟",
                    subtitle: "剩余 \(formatCountdown(remainingSeconds))")
        countdown = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                remainingSeconds -= 1
                if remainingSeconds <= 0 {
                    endTimer()
                } else {
                    store.scenarioSubtitle = "剩余 \(formatCountdown(remainingSeconds))"
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
