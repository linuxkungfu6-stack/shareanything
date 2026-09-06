# Share Anything

支持 macOS、Windows 和 Android。

## 下载

桌面版下载入口指向最新正式版，无需修改链接即可获取后续版本。

| 平台 | 适用设备 | 下载 |
| --- | --- | --- |
| macOS · ARM64 | Apple 芯片（M 系列）Mac | [下载 DMG](https://github.com/linuxkungfu6-stack/shareanything/releases/latest/download/Share.Anything-mac-arm64.dmg) |
| macOS · x64 | Intel 芯片 Mac | [下载 DMG](https://github.com/linuxkungfu6-stack/shareanything/releases/latest/download/Share.Anything-mac-x64.dmg) |
| Windows · x64 | Intel / AMD x64 电脑 | [下载 EXE](https://github.com/linuxkungfu6-stack/shareanything/releases/latest/download/Share.Anything-win-x64.exe) |
| Windows · ARM64 | ARM 架构 Windows 设备 | [下载 EXE](https://github.com/linuxkungfu6-stack/shareanything/releases/latest/download/Share.Anything-win-arm64.exe) |
| Android | 兼容的 Android 设备 | [前往 Google Play](https://play.google.com/store/apps/details?id=com.kungapp.shareanything) |

如果下载链接暂不可用，请前往 [最新 Release](https://github.com/linuxkungfu6-stack/shareanything/releases/latest) 查看 **Assets** 附件。历史版本见 [全部 Releases](https://github.com/linuxkungfu6-stack/shareanything/releases)。

### 如何选择版本

- **Mac**：打开苹果菜单 → 关于本机；M 系列芯片选择 ARM64，Intel 芯片选择 x64。
- **Windows**：打开设置 → 系统 → 关于，查看系统类型；x64 选择 x64 安装包，ARM 选择 ARM64 安装包。
- **Android**：通过 Google Play 安装，设备兼容性及地区可用性以商店页面为准。

### 下载页面

仓库内提供 [下载页面源码](www/index.html)，可在本地用浏览器打开。页面支持中文、英文自动切换，也可手动选择语言。

### 发布时保持下载链接固定

每次发布使用独立版本 tag（例如 `v1.0.0`、`v1.1.0`），将最新正式版设为 **Latest**，并确保 Release 中的附件名称始终与上表链接一致，不带版本号。
