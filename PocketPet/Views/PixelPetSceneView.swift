import SwiftUI

/// 宠物场景合成视图：主体帧动画 + 配饰图层叠加。
/// 主 App 与灵动岛扩展共用 `PixelCat` 数据；这里给 App 用大尺寸版本。
struct PixelPetSceneView: View {
    let state: PetState
    let species: String
    var pixelSize: CGFloat = 10

    private var palette: [Character: Color] { PixelCat.palette(for: species) }
    private var bodyFrames: [PixelSprite] { PixelCat.bodyFrames(for: state) }
    private var accessoryFrames: [PixelSprite]? { PixelCat.accessoryFrames(for: state) }

    var body: some View {
        let bodyW = CGFloat(bodyFrames.first?.width ?? 16) * pixelSize
        let bodyH = CGFloat(bodyFrames.first?.rows.count ?? 13) * pixelSize
        let bodySize = CGSize(width: bodyW, height: bodyH)

        ZStack(alignment: .topLeading) {
            PixelPetAnimationView(frames: bodyFrames,
                                  palette: palette,
                                  interval: state.frameInterval,
                                  pixelSize: pixelSize)
                .frame(width: bodyW, height: bodyH)

            if let acc = accessoryFrames {
                let off = PixelCat.accessoryOffset(for: state, bodySize: bodySize)
                PixelPetAnimationView(frames: acc,
                                      palette: palette,
                                      interval: max(state.frameInterval * 1.5, 0.3),
                                      pixelSize: pixelSize * 0.7)
                    .offset(x: off.x * pixelSize, y: off.y * pixelSize)
            }
        }
        .frame(width: max(bodyW, 220), height: max(bodyH, 180))
        .animation(.easeInOut(duration: 0.25), value: state)
    }
}
