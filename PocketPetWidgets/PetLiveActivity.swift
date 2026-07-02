import SwiftUI
import ActivityKit
import WidgetKit

/// 宠物 Live Activity —— 同时定义锁屏卡片与灵动岛（紧凑 / 最小 / 展开）形态。
/// 宠物状态由 `PetActivityContentState.state` 决定，动画通过 `TimelineView` 驱动。
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // 锁屏展示
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let state = context.state.state
            let species = context.attributes.species
            return DynamicIsland {
                // 展开态
                DynamicIslandExpandedRegion(.leading) {
                    CompactCatView(state: state, species: species)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.petName).font(.caption).bold()
                        Text(state.displayName).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedPetSceneView(state: state,
                                         species: species,
                                         title: context.state.title,
                                         subtitle: context.state.subtitle,
                                         startedAt: context.state.startedAt)
                }
            } compactLeading: {
                CompactCatView(state: state, species: species)
            } compactTrailing: {
                Text(state.emoji)
                    .font(.caption)
            } minimal: {
                CompactCatView(state: state, species: species)
            }
        }
    }
}

/// 锁屏 Live Activity 卡片。
struct LockScreenView: View {
    let context: ActivityViewContext<PetActivityAttributes>
    var body: some View {
        let state = context.state.state
        let species = context.attributes.species
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.petName).font(.headline)
                Spacer()
                Text(state.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(hex: state.accentHex)?.opacity(0.2), in: Capsule())
            }
            ExpandedPetSceneView(state: state,
                                 species: species,
                                 title: context.state.title,
                                 subtitle: context.state.subtitle,
                                 startedAt: context.state.startedAt)
        }
        .padding()
        .activityBackgroundTint(Color(hex: state.accentHex)?.opacity(0.15))
        .activitySystemActionForegroundColor(Color(hex: state.accentHex))
    }
}
