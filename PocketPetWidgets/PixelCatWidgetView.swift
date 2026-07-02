import SwiftUI
import WidgetKit
import ActivityKit

/// 灵动岛 / 锁屏使用的宠物展示组件。复用 `PixelCat` 帧数据，但用更小的像素尺寸。
struct WidgetPetScene: View {
    let state: PetState
    let species: String
    var pixelSize: CGFloat = 3
    var tint: Color? = nil    // 紧凑态用单色剪影，展开态用全彩

    private var palette: [Character: Color] { PixelCat.palette(for: species) }

    var body: some View {
        let frames = PixelCat.bodyFrames(for: state)
        PixelPetAnimationView(frames: frames,
                              palette: palette,
                              interval: state.frameInterval,
                              pixelSize: pixelSize,
                              tint: tint)
    }
}

/// 紧凑模式（灵动岛左右两侧）的小猫剪影。
struct CompactCatView: View {
    let state: PetState
    let species: String
    var body: some View {
        WidgetPetScene(state: state, species: species, pixelSize: 1.4,
                       tint: Color(hex: state.accentHex))
            .frame(width: 24, height: 20, alignment: .center)
    }
}

/// 展开模式 + 锁屏的完整场景。
struct ExpandedPetSceneView: View {
    let state: PetState
    let species: String
    let title: String
    let subtitle: String
    let startedAt: Date

    var body: some View {
        HStack(spacing: 12) {
            WidgetPetScene(state: state, species: species, pixelSize: 4)
                .frame(width: 80, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(state.emoji)
                    Text(title).font(.headline).lineLimit(1)
                }
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                ElapsedText(startedAt: startedAt, accentHex: state.accentHex)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
    }
}

/// 用 TimelineView 实时刷新已持续时长。
struct ElapsedText: View {
    let startedAt: Date
    let accentHex: String
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let s = Int(ctx.date.timeIntervalSince(startedAt))
            Text("已陪伴 \(s / 60)m \(s % 60)s")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(Color(hex: accentHex) ?? .orange)
        }
    }
}
