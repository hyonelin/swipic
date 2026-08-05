import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/album_node.dart';
import '../models/media_item.dart';

/// Abstraction over device photo libraries so demo mode can run without
/// PhotoKit / MediaStore (useful for desktop / CI preview).
abstract class MediaLibraryService {
  Future<List<AlbumNode>> loadAlbumTree();

  Future<List<MediaItem>> loadMedia({
    required String albumId,
    bool recursive = true,
    RequestFilter filter = RequestFilter.all,
  });

  Future<Uint8List?> loadThumbnail(String id, {int size = 400});

  Future<Uint8List?> loadOriginBytes(String id);

  Future<ui.Image?> loadUiImage(String id, {int? maxSize});

  Future<bool> deleteMedia(List<String> ids);

  ImageProvider? imageProvider(MediaItem item, {int thumbSize = 800});
}

extension MediaLibraryServiceX on MediaLibraryService {
  /// Load every accessible asset across the library.
  Future<List<MediaItem>> loadAllMedia({
    RequestFilter filter = RequestFilter.all,
  }) async {
    final tree = await loadAlbumTree();
    AlbumNode? allNode;
    for (final node in tree) {
      if (node.isAll) {
        allNode = node;
        break;
      }
    }
    allNode ??= tree.isEmpty ? null : tree.first;

    if (allNode != null && allNode.isAll) {
      return loadMedia(
        albumId: allNode.id,
        recursive: false,
        filter: filter,
      );
    }

    final seen = <String>{};
    final items = <MediaItem>[];
    for (final root in tree) {
      for (final item in await loadMedia(
        albumId: root.id,
        recursive: true,
        filter: filter,
      )) {
        if (seen.add(item.id)) items.add(item);
      }
    }
    return items;
  }
}

enum RequestFilter { all, images, videos, livePhotos }

@immutable
class MediaQueryOptions {
  const MediaQueryOptions({
    this.recursive = true,
    this.filter = RequestFilter.all,
  });

  final bool recursive;
  final RequestFilter filter;
}
