# PocketPet 🐾

口袋里的像素萌宠 —— 登上 iOS 灵动岛，跟随你的生活节奏变换状态。

> 当前首发宠物：**橘小咪**（像素风格橘猫）。后续会推出更多萌宠并加入成就系统。

## 功能

宠物会根据当前「场景状态」切换动画，并通过 Live Activity 显示在灵动岛 / 锁屏：

| 状态 | 触发场景 | 动画 |
|------|----------|------|
| 💤 打盹 | 长时间无操作 | 闭眼静坐 + Zzz 上浮 |
| 🐾 待机 | 刚启动 / 用户在场 | 正面坐姿 + 偶尔眨眼 |
| 🎵 听歌摇摆 | 播放音乐 | 左右摇摆 + 音符跳动 |
| ⏱ 专注工作 | 打开计时器 | 眼神专注 + 时钟走动 |
| 🗺 看图找路 | 导航中 | 张望 + 拿着地图 |
| 🎮 娱乐时光 | 发消息 / 打游戏 | 上下弹跳 + 手柄按键 |

> ⚠️ iOS 沙盒限制：第三方 App 无法监听其他 App 的播放 / 导航 / 游戏状态。  
> 因此本项目通过**用户主动触发场景**或**App 内事件**驱动 Live Activity 来呈现这些状态。  
> 真机集成时，可把耳机播放、自家导航/游戏逻辑接入 `PetStore.enter(_:title:subtitle:)`。

## 成就系统（部分）

- 🎧 乐迷：累计听歌 10 分钟 / 1 小时 / 10 小时
- 🎮 游戏达人：累计娱乐 10 分钟 / 2 小时 / 10 小时
- 🗺 路痴救星：使用导航 1 / 10 / 100 次（"多少次不知道怎么走"）
- ⏱ 工作狂：专注 25 分钟 / 2 小时 / 10 小时
- 💬 社交蝴蝶：发送消息 1 / 50 / 500 次
- ✨ 全状态图鉴：收集 3 / 5 / 6 种状态
- 💞 忠实陪伴：陪伴 1 小时 / 24 小时 / 7 天
- 🌙 夜猫子 / 🌅 早起鸟：时段彩蛋

## 技术栈

- SwiftUI + ActivityKit（Live Activities，需 iOS 16.1+）
- 像素动画：`Canvas` 逐像素渲染 + `TimelineView` 帧循环，无需图片资源
- XcodeGen 管理工程（`project.yml`）
- GitHub Actions（macOS runner）打包 IPA

## 目录结构

```
PocketPet/
├── project.yml                      # XcodeGen 工程定义
├── Shared/                          # App 与灵动岛扩展共享
│   ├── PetState.swift               # 状态机 + 成就分类
│   ├── Palette.swift                # 像素调色板 + Color(hex:)
│   ├── PixelSprite.swift            # 像素渲染 + 帧动画视图
│   ├── PixelCat.swift               # 小猫各状态帧 + 配饰
│   └── PetActivityAttributes.swift  # Live Activity 数据模型
├── PocketPet/                       # 主 App
│   ├── Models/  State/  Views/
│   └── Info.plist                   # NSSupportsLiveActivities=true
├── PocketPetWidgets/                # 灵动岛 Widget Extension
│   ├── PetLiveActivity.swift        # DynamicIsland 四种形态
│   ├── PixelCatWidgetView.swift
│   └── PocketPetWidgetsBundle.swift
└── .github/workflows/build-ipa.yml  # 打包工作流
```

## 本地构建

```bash
brew install xcodegen
xcodegen generate
open PocketPet.xcodeproj
# 在 Xcode 选择真机 / iPhone 14 Pro 及以上（灵动岛）运行
```

## CI 打包 IPA

推送到 `main` 即触发 GitHub Actions，产出未签名 IPA（artifact：`PocketPet-unsigned-ipa`）。
真机安装需自签名或通过 AltStore / Sideloadly 侧载；如需签名版，在仓库 Secrets 配置
`BUILD_CERTIFICATE_P12` / `P12_PASSWORD` / `BUILD_PROVISION_PROFILE` 后改造工作流。

## 发布到 App Store

本项目已具备上架条件：

- **App 图标**：`scripts/gen_app_icon.py` 生成像素橘猫图标（1024 + 各尺寸），已就位。
- **本地化**：`PocketPet/Resources/` 下 `zh-Hans` / `en` 两套 `Localizable.strings`。
- **隐私政策**：`PRIVACY.md` + App 内“设置 → 隐私政策”页；App Store 元数据见 `fastlane/metadata/`。
- **首次启动引导**、**设置页**、**宠物切换/解锁**、**统计详情**、**触感反馈**均已实现。

上架步骤：
1. 用 Apple Developer 账号在 Xcode 配置签名（Team + Bundle ID `com.goodday1024.PocketPet`）。
2. Archive 后 Distribute App → App Store Connect。
3. 在 App Store Connect 填写截图、审核信息（可参考 `fastlane/metadata/` 中的描述与关键词）。
4. 提交审核。审核要点：Live Activity 为本地展示无后台行为，隐私问卷全部选“否”。

> 灵动岛仅在 iPhone 14 Pro 及以上机型显示；锁屏 Live Activity 在所有支持 iOS 16.2+ 的机型可用。
