import SwiftUI

/// 全局像素调色板。字符键 -> SwiftUI Color。
/// 所有宠物帧共享同一套键，不同宠物可覆盖（例如黑猫把 O 替换为深色）。
public enum PetPalette {
    /// 默认橘猫调色板。
    public static let orangeTabby: [Character: Color] = [
        "#": Color(red: 0.16, green: 0.10, blue: 0.07), // 描边 / 深棕
        "-": Color(red: 0.16, green: 0.10, blue: 0.07), // 闭眼线（同描边色）
        "O": Color(red: 1.00, green: 0.62, blue: 0.24), // 橘色主毛
        "o": Color(red: 0.84, green: 0.44, blue: 0.14), // 橘色阴影 / 虎斑
        "W": Color(red: 1.00, green: 0.94, blue: 0.82), // 肚子奶油色
        "P": Color(red: 1.00, green: 0.60, blue: 0.70), // 粉色鼻头 / 内耳
        "B": Color(red: 0.08, green: 0.06, blue: 0.05), // 黑色眼珠
        "G": Color(red: 0.40, green: 0.84, blue: 0.45), // 绿色眼高光
        "Z": Color(red: 0.52, green: 0.83, blue: 1.00), // zzz 蓝
        "N": Color(red: 1.00, green: 0.82, blue: 0.28), // 音符黄
        "M": Color(red: 0.80, green: 0.61, blue: 0.40), // 地图卡其
        "m": Color(red: 0.34, green: 0.27, blue: 0.20), // 地图线条
        "C": Color(red: 0.18, green: 0.20, blue: 0.26), // 手柄深灰
        "c": Color(red: 0.86, green: 0.30, blue: 0.30), // 手柄红键
        "Y": Color(red: 0.98, green: 0.86, blue: 0.32), // 表盘黄
        "R": Color(red: 0.91, green: 0.30, blue: 0.27), // 秒针红
        "H": Color(red: 0.95, green: 0.95, blue: 0.95), // 高光白
    ]

    /// 后续可扩展：黑猫、白猫、布偶猫等。每种宠物提供一份调色板覆盖即可。
    public static let blackCat: [Character: Color] = orangeTabby.merging([
        "O": Color(red: 0.18, green: 0.18, blue: 0.20),
        "o": Color(red: 0.10, green: 0.10, blue: 0.12),
        "W": Color(red: 0.55, green: 0.55, blue: 0.58),
    ]) { _, new in new }
}

/// 从十六进制字符串构造颜色，供 App 与灵动岛扩展共用。
public extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xff) / 255
        let g = Double((v >> 8) & 0xff) / 255
        let b = Double(v & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
