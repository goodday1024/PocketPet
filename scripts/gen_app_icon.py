"""生成 PocketPet App 图标：圆角渐变背景 + 像素橘猫脸。

输出 1024x1024 主图标，并按需缩放生成常见尺寸到 AppIcon.appiconset。
"""
import os
from PIL import Image, ImageDraw

PALETTE = {
    "#": (40, 26, 18),       # 描边深棕
    "O": (255, 158, 61),     # 橘色主毛
    "o": (214, 112, 36),     # 橘色阴影
    "W": (255, 240, 209),    # 肚子奶油
    "P": (255, 153, 178),    # 粉色鼻头 / 内耳
    "B": (20, 15, 12),       # 黑眼珠
    "G": (102, 214, 115),    # 绿色眼高光
    "H": (255, 255, 255),    # 高光白
}

# 24x24 像素橘猫脸（居中、睁眼带高光）
CAT = [
    "........................",
    "........................",
    "....##........##........",
    "...#OO#......#OO#.......",
    "..#OOOO######OOOO#......",
    "..#OOOOOOOOOOOOOO#......",
    ".#OOOOOOOOOOOOOOOO#.....",
    ".#OOOGBOOOOOOBGOOO#.....",
    ".#OOOOOOOPPOOOOOOO#.....",
    ".#OOOOOO##OO##OOOO#.....",
    ".#OOOOWWWWWWWWWWOO#.....",
    ".#OOOOWWWWWWWWWWOO#.....",
    ".#OOOOWWWWWWWWWWOO#.....",
    ".#OO##WWWWWWWWWW##O#....",
    "..###############.......",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(size: int) -> Image.Image:
    # 背景：橙色到奶油色的垂直渐变
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    top = (255, 196, 110)
    bottom = (255, 235, 200)
    for y in range(size):
        t = y / max(size - 1, 1)
        bg.putpixel  # noqa
    # 用渐变填充
    grad = Image.new("RGBA", (1, size))
    for y in range(size):
        t = y / max(size - 1, 1)
        grad.putpixel((0, y), lerp(top, bottom, t) + (255,))
    bg = grad.resize((size, size))
    img.paste(bg, (0, 0))

    # 圆角遮罩（iOS superellipse-like，这里用圆角矩形即可）
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    radius = int(size * 0.22)
    md.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rounded.paste(bg, (0, 0), mask)
    img = rounded

    # 绘制像素猫
    cat_w = len(CAT[0])
    cat_h = len(CAT)
    # 缩放比例：让猫脸占图标 ~62%
    pixel = max(1, size // 36)
    draw_w = cat_w * pixel
    draw_h = cat_h * pixel
    ox = (size - draw_w) // 2
    oy = (size - draw_h) // 2 - int(size * 0.02)
    draw = ImageDraw.Draw(img)
    for y, row in enumerate(CAT):
        for x, ch in enumerate(row):
            if ch == "." or ch not in PALETTE:
                continue
            color = PALETTE[ch]
            x0 = ox + x * pixel
            y0 = oy + y * pixel
            draw.rectangle([x0, y0, x0 + pixel - 1, y0 + pixel - 1], fill=color)

    return img


def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(repo_root,
                           "PocketPet", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(out_dir, exist_ok=True)
    sizes = [1024, 180, 120, 87, 80, 60, 40, 29]
    filenames = {}
    for s in sizes:
        fn = f"icon_{s}.png"
        img = make_icon(s)
        img.save(os.path.join(out_dir, fn))
        filenames[s] = fn
        print("wrote", fn, img.size)

    # Contents.json：iOS 14+ 单尺寸 1024 即足够，但补全通用尺寸以兼容老配置。
    import json
    images = [
        {"filename": filenames[1024], "idiom": "universal", "platform": "ios", "size": "1024x1024"}
    ]
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    with open(os.path.join(out_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print("wrote Contents.json")


if __name__ == "__main__":
    main()
