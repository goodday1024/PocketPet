import SwiftUI

/// 单帧像素图：由若干行字符串组成，每个字符对应调色板中的一个颜色键。
/// `.` 表示透明。行长度可以不一致（不足部分按透明处理）。
public struct PixelSprite: Sendable, Hashable {
    public let rows: [String]
    public let width: Int

    public init(_ rows: [String]) {
        self.rows = rows
        self.width = rows.map { $0.count }.max() ?? 0
    }

    public func character(at x: Int, y: Int) -> Character? {
        guard y >= 0, y < rows.count else { return nil }
        let row = rows[y]
        guard x >= 0, x < row.count else { return nil }
        let idx = row.index(row.startIndex, offsetBy: x)
        let ch = row[idx]
        return ch == "." ? nil : ch
    }
}

/// 把 PixelSprite 绘制成 SwiftUI 视图。使用 Canvas 批量填充矩形，性能足够支撑多帧动画。
public struct PixelSpriteView: View {
    public let sprite: PixelSprite
    public let palette: [Character: Color]
    public let pixelSize: CGFloat        // 单个像素的边长（pt）
    public let tint: Color?              // 可选整体染色（例如灵动岛单色模式）

    public init(sprite: PixelSprite,
                palette: [Character: Color],
                pixelSize: CGFloat = 8,
                tint: Color? = nil) {
        self.sprite = sprite
        self.palette = palette
        self.pixelSize = pixelSize
        self.tint = tint
    }

    public var body: some View {
        Canvas { context, _ in
            for y in 0..<sprite.rows.count {
                let row = sprite.rows[y]
                for x in 0..<row.count {
                    let ch = row[row.index(row.startIndex, offsetBy: x)]
                    if ch == "." { continue }
                    let base = palette[ch] ?? .gray
                    let color = tint ?? base
                    let rect = CGRect(x: CGFloat(x) * pixelSize,
                                      y: CGFloat(y) * pixelSize,
                                      width: pixelSize,
                                      height: pixelSize)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(sprite.width) * pixelSize,
               height: CGFloat(sprite.rows.count) * pixelSize)
    }
}

/// 帧动画视图：根据状态在帧之间循环。使用 TimelineView 周期刷新，
/// 这一点对 Live Activity 同样适用（灵动岛内动画依赖 TimelineView）。
public struct PixelPetAnimationView: View {
    public let frames: [PixelSprite]
    public let palette: [Character: Color]
    public let interval: TimeInterval
    public let pixelSize: CGFloat
    public let tint: Color?

    public init(frames: [PixelSprite],
                palette: [Character: Color],
                interval: TimeInterval,
                pixelSize: CGFloat = 6,
                tint: Color? = nil) {
        self.frames = frames
        self.palette = palette
        self.interval = max(interval, 0.05)
        self.pixelSize = pixelSize
        self.tint = tint
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { timeline in
            let index = frameIndex(at: timeline.date)
            PixelSpriteView(sprite: frames[index],
                            palette: palette,
                            pixelSize: pixelSize,
                            tint: tint)
                .id(index)
        }
    }

    private func frameIndex(at date: Date) -> Int {
        guard !frames.isEmpty else { return 0 }
        let slot = Int(date.timeIntervalSinceReferenceDate / interval)
        return slot % frames.count
    }
}
