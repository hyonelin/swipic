# 演示图库调整说明

演示模式的数据由 `lib/services/demo_library_service.dart` 在本地生成，不依赖真实照片文件。后续要调整演示照片、相册、视频或重复项，主要改这个文件。

## 常改位置

1. `_seed()`

   这里定义演示相册和媒体列表。可以增删循环数量、相册名称、媒体类型和相册层级。

2. `_makeItem(...)`

   这里创建单个 `MediaItem`。常用字段：

   - `id`：唯一标识，不能重复。
   - `albumId` / `albumName`：所属相册。
   - `kind`：`MediaKind.image`、`MediaKind.video` 或 `MediaKind.livePhoto`。
   - `date`：拍摄时间，影响排序。
   - `w` / `h`：展示用宽高。
   - `hue`：生成示例图的主色。
   - `sizeFactor`：模拟文件大小。
   - `duration`：视频时长。

3. `cloneFrom` / `similarTo`

   - `cloneFrom: 'camera_1'` 会生成完全重复图。
   - `similarTo: 'camera_3'` 会生成相似图，用于查重演示。

4. `_tree`

   这里定义首页看到的相册树。新增相册后，需要在 `_tree` 中加对应 `AlbumNode`，并设置 `assetCount`。

## 示例

新增一张演示照片：

```dart
camera.add(
  _makeItem(
    id: 'camera_new_0',
    albumId: 'album_camera',
    albumName: '相机胶卷',
    kind: MediaKind.image,
    date: now.subtract(const Duration(hours: 2)),
    w: 4032,
    h: 3024,
    hue: 18,
    sizeFactor: 1.1,
  ),
);
```

新增一个视频：

```dart
camera.add(
  _makeItem(
    id: 'video_new_0',
    albumId: 'album_camera',
    albumName: '相机胶卷',
    kind: MediaKind.video,
    date: now.subtract(const Duration(hours: 1)),
    w: 3840,
    h: 2160,
    hue: 210,
    sizeFactor: 2.0,
    duration: const Duration(seconds: 18),
  ),
);
```

## 验证

修改后运行：

```bash
flutter test
flutter run -d chrome
```

桌面和 Web 会自动使用演示图库；真机上可在「设置」中开启演示模式。
