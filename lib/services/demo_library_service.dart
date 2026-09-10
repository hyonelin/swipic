import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

import '../models/album_node.dart';
import '../models/media_item.dart';
import 'media_library_service.dart';

/// Offline demo library with nested albums, live photos, videos, and duplicates.
class DemoLibraryService implements MediaLibraryService {
  DemoLibraryService() {
    _seed();
  }

  final Map<String, MediaItem> _items = {};
  final Map<String, Uint8List> _bytes = {};
  late List<AlbumNode> _tree;

  void _seed() {
    final now = DateTime.now();
    final travel = <MediaItem>[];
    final tokyo = <MediaItem>[];
    final camera = <MediaItem>[];
    final screenshots = <MediaItem>[];

    // Nested: 旅行 › 东京
    for (var i = 0; i < 8; i++) {
      final item = _makeItem(
        id: 'tokyo_$i',
        albumId: 'album_tokyo',
        albumName: '东京',
        kind: i == 2 ? MediaKind.livePhoto : MediaKind.image,
        date: now.subtract(Duration(days: 40 + i)),
        w: 3000 + i * 20,
        h: 2000,
        hue: 200 + i * 8,
        sizeFactor: 1.0 + i * 0.05,
      );
      tokyo.add(item);
    }

    // Parent travel album extras
    for (var i = 0; i < 4; i++) {
      travel.add(
        _makeItem(
          id: 'travel_$i',
          albumId: 'album_travel',
          albumName: '旅行',
          kind: MediaKind.image,
          date: now.subtract(Duration(days: 60 + i)),
          w: 2800,
          h: 1800,
          hue: 30 + i * 12,
          sizeFactor: 0.9,
        ),
      );
    }

    // Camera roll with intentional duplicates / similar pairs
    for (var i = 0; i < 12; i++) {
      camera.add(
        _makeItem(
          id: 'camera_$i',
          albumId: 'album_camera',
          albumName: '相机胶卷',
          kind: i % 5 == 0 ? MediaKind.video : MediaKind.image,
          date: now.subtract(Duration(hours: i * 5)),
          w: 4000,
          h: 3000,
          hue: 120 + i * 15,
          sizeFactor: 1.2,
          duration: i % 5 == 0 ? Duration(seconds: 8 + i) : null,
        ),
      );
    }

    // Exact duplicate of camera_1 with smaller size
    camera.add(
      _makeItem(
        id: 'camera_1_dup',
        albumId: 'album_camera',
        albumName: '相机胶卷',
        kind: MediaKind.image,
        date: now.subtract(const Duration(hours: 4)),
        w: 4000,
        h: 3000,
        hue: 135,
        sizeFactor: 0.55,
        cloneFrom: 'camera_1',
      ),
    );

    // Similar (same scene, slightly different)
    camera.add(
      _makeItem(
        id: 'camera_3_similar',
        albumId: 'album_screenshots',
        albumName: '截屏',
        kind: MediaKind.image,
        date: now.subtract(const Duration(hours: 14)),
        w: 3800,
        h: 2800,
        hue: 165,
        sizeFactor: 0.8,
        similarTo: 'camera_3',
      ),
    );

    for (var i = 0; i < 5; i++) {
      screenshots.add(
        _makeItem(
          id: 'shot_$i',
          albumId: 'album_screenshots',
          albumName: '截屏',
          kind: MediaKind.image,
          date: now.subtract(Duration(days: i)),
          w: 1170,
          h: 2532,
          hue: 260 + i * 5,
          sizeFactor: 0.4,
        ),
      );
    }

    for (final item in [...travel, ...tokyo, ...camera, ...screenshots]) {
      _items[item.id] = item;
    }

    // Ensure similar pair shares nearly identical bytes pattern
    if (_bytes.containsKey('camera_3')) {
      _bytes['camera_3_similar'] = Uint8List.fromList(_bytes['camera_3']!);
      // Slight mutation for similar-not-exact
      final mutated = Uint8List.fromList(_bytes['camera_3_similar']!);
      if (mutated.length > 200) mutated[120] = (mutated[120] + 3) % 256;
      _bytes['camera_3_similar'] = mutated;
    }

    _tree = [
      AlbumNode(
        id: 'album_all',
        name: '所有照片',
        assetCount: _items.length,
        isAll: true,
        children: const [],
      ),
      AlbumNode(
        id: 'album_camera',
        name: '相机胶卷',
        assetCount: camera.length,
        children: const [],
      ),
      AlbumNode(
        id: 'album_travel',
        name: '旅行',
        assetCount: travel.length + tokyo.length,
        children: [
          AlbumNode(
            id: 'album_tokyo',
            name: '东京',
            assetCount: tokyo.length,
            parentId: 'album_travel',
            depth: 1,
          ),
        ],
      ),
      AlbumNode(
        id: 'album_screenshots',
        name: '截屏',
        assetCount: screenshots.length + 1,
        children: const [],
      ),
    ];
  }

  MediaItem _makeItem({
    required String id,
    required String albumId,
    required String albumName,
    required MediaKind kind,
    required DateTime date,
    required int w,
    required int h,
    required double hue,
    required double sizeFactor,
    Duration? duration,
    String? cloneFrom,
    String? similarTo,
  }) {
    final bytes = cloneFrom != null && _bytes.containsKey(cloneFrom)
        ? Uint8List.fromList(_bytes[cloneFrom]!)
        : similarTo != null && _bytes.containsKey(similarTo)
            ? Uint8List.fromList(_bytes[similarTo]!)
            : _generateJpeg(w: 480, h: ((480 * h) / w).round(), hue: hue, seed: id.hashCode);

    _bytes[id] = bytes;
    final byteSize = (bytes.length * sizeFactor * (kind == MediaKind.video ? 12 : 1))
        .round();

    return MediaItem(
      id: id,
      albumId: albumId,
      albumName: albumName,
      kind: kind,
      createDate: date,
      width: w,
      height: h,
      byteSize: byteSize,
      duration: duration,
      latitude: 35.68 + (id.hashCode % 100) / 10000,
      longitude: 139.76 + (id.hashCode % 80) / 10000,
      mimeType: kind == MediaKind.video ? 'video/mp4' : 'image/jpeg',
      title: id,
    );
  }

  Uint8List _generateJpeg({
    required int w,
    required int h,
    required double hue,
    required int seed,
  }) {
    final image = img.Image(width: w, height: h);
    final rnd = math.Random(seed);
    final base = img.ColorRgb8(
      _hueToRgb(hue, 0.55, 0.55).$1,
      _hueToRgb(hue, 0.55, 0.55).$2,
      _hueToRgb(hue, 0.55, 0.55).$3,
    );
    final accent = img.ColorRgb8(
      _hueToRgb(hue + 40, 0.7, 0.65).$1,
      _hueToRgb(hue + 40, 0.7, 0.65).$2,
      _hueToRgb(hue + 40, 0.7, 0.65).$3,
    );

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final t = (x + y) / (w + h);
        final noise = rnd.nextDouble() * 18;
        final r = (base.r * (1 - t) + accent.r * t + noise).clamp(0, 255).toInt();
        final g = (base.g * (1 - t) + accent.g * t + noise).clamp(0, 255).toInt();
        final b = (base.b * (1 - t) + accent.b * t + noise).clamp(0, 255).toInt();
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    // Soft circle as subject
    img.fillCircle(
      image,
      x: w ~/ 2,
      y: h ~/ 2,
      radius: math.min(w, h) ~/ 5,
      color: img.ColorRgb8(255, 255, 255),
    );

    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  (int, int, int) _hueToRgb(double h, double s, double l) {
    final c = (1 - (2 * l - 1).abs()) * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = l - c / 2;
    double r = 0, g = 0, b = 0;
    final hh = h % 360;
    if (hh < 60) {
      r = c;
      g = x;
    } else if (hh < 120) {
      r = x;
      g = c;
    } else if (hh < 180) {
      g = c;
      b = x;
    } else if (hh < 240) {
      g = x;
      b = c;
    } else if (hh < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }
    return (
      ((r + m) * 255).round().clamp(0, 255),
      ((g + m) * 255).round().clamp(0, 255),
      ((b + m) * 255).round().clamp(0, 255),
    );
  }

  @override
  Future<List<AlbumNode>> loadAlbumTree() async => _tree;

  @override
  Future<List<MediaItem>> loadMedia({
    required String albumId,
    bool recursive = true,
    RequestFilter filter = RequestFilter.all,
  }) async {
    Iterable<MediaItem> all = _items.values;

    if (albumId != 'album_all') {
      final node = _findNode(albumId);
      final ids = recursive && node != null
          ? node.collectIds()
          : {albumId};
      all = all.where((m) => ids.contains(m.albumId));
    }

    switch (filter) {
      case RequestFilter.all:
        break;
      case RequestFilter.images:
        all = all.where((m) => m.kind == MediaKind.image);
      case RequestFilter.videos:
        all = all.where((m) => m.isVideo);
      case RequestFilter.livePhotos:
        all = all.where((m) => m.isLivePhoto);
    }

    final list = all.toList()
      ..sort((a, b) => b.createDate.compareTo(a.createDate));
    return list;
  }

  AlbumNode? _findNode(String id) {
    AlbumNode? walk(List<AlbumNode> nodes) {
      for (final n in nodes) {
        if (n.id == id) return n;
        final child = walk(n.children);
        if (child != null) return child;
      }
      return null;
    }

    return walk(_tree);
  }

  @override
  Future<Uint8List?> loadThumbnail(String id, {int size = 400}) async {
    final bytes = _bytes[id];
    if (bytes == null) return null;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = img.copyResize(decoded, width: size);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  @override
  Future<Uint8List?> loadOriginBytes(String id) async => _bytes[id];

  @override
  Future<ui.Image?> loadUiImage(String id, {int? maxSize}) async {
    final bytes = await loadThumbnail(id, size: maxSize ?? 1200);
    if (bytes == null) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Future<bool> deleteMedia(List<String> ids) async {
    for (final id in ids) {
      _items.remove(id);
      _bytes.remove(id);
    }
    // Refresh counts
    _tree = _tree.map((n) {
      int countFor(AlbumNode node) {
        final ids = node.collectIds();
        return _items.values.where((m) => ids.contains(m.albumId)).length;
      }

      AlbumNode refresh(AlbumNode node) {
        return node.copyWith(
          assetCount: node.isAll
              ? _items.length
              : countFor(node),
          children: node.children.map(refresh).toList(),
        );
      }

      return refresh(n);
    }).toList();
    return true;
  }

  @override
  ImageProvider? imageProvider(MediaItem item, {int thumbSize = 800}) {
    final bytes = _bytes[item.id];
    if (bytes == null) return null;
    return MemoryImage(bytes);
  }
}
