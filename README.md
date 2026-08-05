# Swipic

离线优先的 iOS / Android 照片清理应用：左右滑动保留或标记删除，支持嵌套相册、EXIF、实况照片 / 视频，以及本地相似 / 重复检测。

## 功能

1. **相册浏览**：支持相册套相册；清理时可递归包含子相册内容。
2. **滑动清理**：右滑保留，左滑标记删除；可撤销；点击查看大图。
3. **放大与 EXIF**：双击 / 捏合放大；底部可查看拍摄信息。
4. **待删除队列**：滑动删除只是标记，统一确认后才真正从系统相册删除。
5. **相似 / 重复检测**：完全离线（内容哈希 + aHash）；可选保留更清晰 / 更大 / 更小 / 最新 / 最旧 / 某相册内的照片。
6. **实况与视频**：识别 Live Photo 与视频，并在卡片上展示标识。
7. **隐私**：Release 构建不声明 `INTERNET` 权限；分析均在本地完成。
8. **首次启动授权**：一次性请求照片 / 视频 / 媒体位置等权限。

## 技术栈

- Flutter + Riverpod
- `photo_manager`（真机相册）
- 内置演示图库（桌面 / 无权限环境可完整体验）

## 开始

```bash
flutter pub get
flutter test
flutter run -d <ios|android>
```

桌面预览会自动进入演示模式：

```bash
flutter run -d chrome
# 或
flutter run -d linux
```

真机上请在「设置」关闭演示模式，以访问系统相册。

## 盈利建议（与离线定位兼容）

| 方案 | 是否需要应用联网 | 建议 |
|------|------------------|------|
| App Store / Play **付费下载** | 否 | 最推荐 |
| 一次性 IAP 解锁 Pro | 仅系统商店购买瞬间 | 可接受 |
| 订阅 / 云同步 / 广告 | 是 | 不建议 |

## 目录结构

```
lib/
  models/       媒体、相册树、EXIF、重复组
  services/     权限、图库、EXIF、查重、待删除
  providers/    Riverpod 状态
  screens/      引导、首页、相册、滑动、待删除、查重、详情、设置
  widgets/      滑动卡片、缩略图、缩放查看等
  theme/        iOS 风格浅色主题
```

## 权限说明

**iOS**（`Info.plist`）

- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSLocationWhenInUseUsageDescription`（仅用于展示 EXIF 地点）

**Android**（`AndroidManifest.xml`）

- `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`
- `READ_MEDIA_VISUAL_USER_SELECTED`
- `ACCESS_MEDIA_LOCATION`
- 旧版存储权限（按 SDK 上限限制）
- 显式 `tools:node="remove"` 移除 `INTERNET`
