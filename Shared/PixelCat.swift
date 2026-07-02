import Foundation
import SwiftUI

/// 小猫像素图集。所有帧均为 16 宽，行内字符对应 `PetPalette.orangeTabby`。
///
/// 设计思路：
/// - 主体（body）帧：坐姿橘猫，通过 `open` / `blink` 两个基础帧 + `shifted()` 位移
///   派生出摇摆（music）、弹跳（playing）、转头（working/navigating）等动画。
/// - 配饰（accessory）帧：Zzz / 音符 / 地图 / 时钟 / 手柄，作为独立小精灵图，
///   由 `PixelPetSceneView` 叠加在主体周围，单独循环动画。
/// - 后续新增宠物（狗 / 兔…）只需提供同结构的 body + accessory 即可复用整套渲染与状态机。
public enum PixelCat {

    // MARK: - 基础帧（16 宽 × 13 高）

    /// 眼睛睁开、正面坐姿。
    static let open: PixelSprite = PixelSprite([
        "....##....##....",
        "...#OO#..#OO#...",
        "..#OOOO##OOOO#..",
        "..#OOOOOOOOOO#..",
        ".#OOOOOOOOOOOO#.",
        ".#OOOGBOOOBGOO#.",
        ".#OOOOOOPPOOOO#.",
        ".#OOOOO##OOOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OO##WWWW##OO#.",
        "..############..",
    ])

    /// 眨眼 / 闭眼（眼珠换成 `-` 闭眼线）。
    static let blink: PixelSprite = PixelSprite([
        "....##....##....",
        "...#OO#..#OO#...",
        "..#OOOO##OOOO#..",
        "..#OOOOOOOOOO#..",
        ".#OOOOOOOOOOOO#.",
        ".#OOOO--OO--OO#.",
        ".#OOOOOOPPOOOO#.",
        ".#OOOOO##OOOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OO##WWWW##OO#.",
        "..############..",
    ])

    /// 工作状态：眼珠向右看（专注计时器）。
    static let lookRight: PixelSprite = PixelSprite([
        "....##....##....",
        "...#OO#..#OO#...",
        "..#OOOO##OOOO#..",
        "..#OOOOOOOOOO#..",
        ".#OOOOOOOOOOOO#.",
        ".#OOOOGBOOOBGO#.",
        ".#OOOOOOPPOOOO#.",
        ".#OOOOO##OOOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OO##WWWW##OO#.",
        "..############..",
    ])

    /// 娱乐状态：兴奋大眼（眼珠变 G 亮绿）。
    static let excited: PixelSprite = PixelSprite([
        "....##....##....",
        "...#OO#..#OO#...",
        "..#OOOO##OOOO#..",
        "..#OOOOOOOOOO#..",
        ".#OOOOOOOOOOOO#.",
        ".#OOOGGOOOGGOO#.",
        ".#OOOOOOPPOOOO#.",
        ".#OOOOO##OOOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OOOOWWWWWOOO#.",
        ".#OO##WWWW##OO#.",
        "..############..",
    ])

    // MARK: - 位移工具

    /// 把精灵图整体平移 (dx, dy)，画布相应扩大以容纳偏移，保证内容不被裁切。
    /// 同一组动画里所有帧使用相同幅度的位移，画布尺寸保持一致。
    public static func shifted(_ sprite: PixelSprite, dx: Int = 0, dy: Int = 0) -> PixelSprite {
        let w = sprite.width
        let h = sprite.rows.count
        let newW = w + abs(dx)
        let newH = h + abs(dy)
        let offX = dx >= 0 ? dx : 0
        let offY = dy >= 0 ? dy : 0
        var grid: [[Character]] = Array(repeating: Array(repeating: Character("."), count: newW), count: newH)
        for y in 0..<h {
            for x in 0..<w {
                if let ch = sprite.character(at: x, y: y), ch != "." {
                    grid[y + offY][x + offX] = ch
                }
            }
        }
        return PixelSprite(grid.map { String($0) })
    }

    // MARK: - 主体帧（按状态返回）

    /// 返回某状态下的主体动画帧序列（不含配饰）。
    public static func bodyFrames(for state: PetState) -> [PixelSprite] {
        switch state {
        case .idle:
            // 偶尔眨眼
            return [open, open, open, blink]
        case .sleeping:
            // 闭眼静坐 + 轻微起伏
            return [blink, shifted(blink, dy: 1)]
        case .music:
            // 左右摇摆
            return [shifted(open, dx: -1), shifted(open, dx: 1)]
        case .working:
            // 专注：向右看 <-> 正视
            return [lookRight, open]
        case .navigating:
            // 看地图：左右张望
            return [lookRight, shifted(open, dx: -1)]
        case .playing:
            // 上下弹跳（兴奋大眼）
            return [shifted(excited, dy: -1), shifted(excited, dy: 1)]
        }
    }

    // MARK: - 配饰精灵

    /// 打盹的 Zzz（3 帧上升）。
    static let zzzFrames: [PixelSprite] = [
        PixelSprite([
            "........",
            "....Z...",
            "...Z....",
            "..Z.....",
        ]),
        PixelSprite([
            "....Z...",
            "...Z....",
            "..Z.....",
            "........",
        ]),
        PixelSprite([
            "...Z....",
            "..Z.....",
            ".Z......",
            "........",
        ]),
    ]

    /// 音乐音符（2 帧跳动）。
    static let noteFrames: [PixelSprite] = [
        PixelSprite([
            "..N...",
            "..N...",
            "..N...",
            ".NNNN.",
            ".N....",
            "NN....",
        ]),
        PixelSprite([
            "...N..",
            "...N..",
            "...N..",
            "NNNNN.",
            "....N.",
            "...NN.",
        ]),
    ]

    /// 地图（静态，导航时拿在爪前）。
    static let map: PixelSprite = PixelSprite([
        "MMMMMMMMMM",
        "MmmmmMmmmM",
        "Mm..mM..mM",
        "Mm..mM..mM",
        "MmmmmMmmmM",
        "MMMMMMMMMM",
    ])

    /// 计时器表盘（2 帧：指针走动）。
    static let clockFrames: [PixelSprite] = [
        PixelSprite([
            ".YYYY.",
            "YYYYYY",
            "YYBYYY",
            "YYBRYY",
            "YYYYYY",
            ".YYYY.",
        ]),
        PixelSprite([
            ".YYYY.",
            "YYYYYY",
            "YYYBYY",
            "YYBRYY",
            "YYYYYY",
            ".YYYY.",
        ]),
    ]

    /// 游戏手柄（2 帧：按键闪烁）。
    static let controllerFrames: [PixelSprite] = [
        PixelSprite([
            ".CCCCCC.",
            "CCCCCCCC",
            "C#B##B#C",
            "CC#cc#CC",
            ".CCCCCC.",
        ]),
        PixelSprite([
            ".CCCCCC.",
            "CCCCCCCC",
            "C#B##B#C",
            "CC#cc#CC",
            ".CCCCCC.",
        ]),
    ]

    // MARK: - 配饰帧（按状态返回）

    /// 返回某状态的配饰动画帧（可能为空）。
    public static func accessoryFrames(for state: PetState) -> [PixelSprite]? {
        switch state {
        case .sleeping:   return zzzFrames
        case .music:      return noteFrames
        case .working:    return clockFrames
        case .navigating: return [map]
        case .playing:    return controllerFrames
        case .idle:       return nil
        }
    }

    /// 配饰相对于主体右上的偏移（pt，基于 pixelSize=1 的坐标）。
    public static func accessoryOffset(for state: PetState, bodySize: CGSize) -> CGPoint {
        switch state {
        case .sleeping, .music, .working:
            // 右上角飘浮
            return CGPoint(x: bodySize.width - 6, y: 0)
        case .navigating:
            // 爪前正下方
            return CGPoint(x: bodySize.width / 2 - 5, y: bodySize.height - 12)
        case .playing:
            // 右侧
            return CGPoint(x: bodySize.width - 8, y: bodySize.height / 2)
        case .idle:
            return .zero
        }
    }

    // MARK: - 调色板桥接

    /// 当前宠物的调色板（按 species 切换）。
    public static func palette(for species: String) -> [Character: Color] {
        switch species {
        case "blackCat": return PetPalette.blackCat
        case "whiteCat": return PetPalette.whiteCat
        default:         return PetPalette.orangeTabby
        }
    }
}
