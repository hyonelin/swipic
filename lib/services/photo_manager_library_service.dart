import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../models/album_node.dart';
import '../models/media_item.dart';
import 'media_library_service.dart';

class PhotoManagerLibraryService implements MediaLibraryService {
  final Map<String, AssetEntity> _assetCache = {};

  @override
  Future<List<AlbumNode>> loadAlbumTree() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    // Build parent/child relationships.
    // iOS albums may nest via albumType / darwin; Android uses relativePath.
    final nodesById = <String, AlbumNode>{};
    final childrenMap = <String, List<String>>{};
    final roots = <String>[];

    for (final path in paths) {
      final count = await path.assetCountAsync;
      final parentId = await _resolveParentId(path, paths);
      final node = AlbumNode(
        id: path.id,
        name: path.name,
        assetCount: count,
        parentId: parentId,
        isAll: path.isAll,
        isSmart: path.albumType == 2,
      );
      nodesById[path.id] = node;
      if (parentId == null || !paths.any((p) => p.id == parentId)) {
        roots.add(path.id);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(path.id);
      }
    }

    AlbumNode build(String id, int depth) {
      final base = nodesById[id]!;
      final childIds = childrenMap[id] ?? const [];
      final children = childIds.map((cid) => build(cid, depth + 1)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return base.copyWith(children: children, depth: depth);
    }

    // Prefer "Recent / All" first, then alphabetical.
    final rootNodes = roots.map((id) => build(id, 0)).toList()
      ..sort((a, b) {
        if (a.isAll != b.isAll) return a.isAll ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return rootNodes;
  }

  Future<String?> _resolveParentId(
    AssetPathEntity path,
    List<AssetPathEntity> all,
  ) async {
    // Android: infer nesting from relativePath folders.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // photo_manager exposes darwin/android specifics via albumType / name.
      // Folder nesting often appears as "Camera" under "DCIM" style names.
      // We heuristically nest when a path name contains '/' separators.
      if (path.name.contains('/')) {
        final parts = path.name.split('/');
        if (parts.length > 1) {
          final parentName = parts.sublist(0, parts.length - 1).join('/');
          final parent = all.cast<AssetPathEntity?>().firstWhere(
            (p) => p?.name == parentName,
            orElse: () => null,
          );
          return parent?.id;
        }
      }
    }

    // iOS: PhotoKit can expose album subsets. photo_manager 3.x does not always
    // surface parent album IDs, so we keep a flat list unless names suggest nesting.
    if (path.name.contains(' › ') || path.name.contains(' / ')) {
      final separator = path.name.contains(' › ') ? ' › ' : ' / ';
      final parts = path.name.split(separator);
      if (parts.length > 1) {
        final parentName = parts.sublist(0, parts.length - 1).join(separator);
        final parent = all.cast<AssetPathEntity?>().firstWhere(
          (p) => p?.name == parentName,
          orElse: () => null,
        );
        return parent?.id;
      }
    }
    return null;
  }

  @override
  Future<List<MediaItem>> loadMedia({
    required String albumId,
    bool recursive = true,
    RequestFilter filter = RequestFilter.all,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      type: _toRequestType(filter),
      hasAll: true,
    );
    final path = paths.cast<AssetPathEntity?>().firstWhere(
      (p) => p?.id == albumId,
      orElse: () => null,
    );
    if (path == null) return [];

    final total = await path.assetCountAsync;
    final entities = <AssetEntity>[];
    const pageSize = 80;
    for (var i = 0; i < total; i += pageSize) {
      entities.addAll(
        await path.getAssetListRange(
          start: i,
          end: (i + pageSize).clamp(0, total),
        ),
      );
    }

    // If recursive, also pull media from nested child albums.
    if (recursive && !path.isAll) {
      final tree = await loadAlbumTree();
      AlbumNode? findNode(List<AlbumNode> nodes) {
        for (final n in nodes) {
          if (n.id == albumId) return n;
          final nested = findNode(n.children);
          if (nested != null) return nested;
        }
        return null;
      }

      final node = findNode(tree);
      if (node != null && node.hasChildren) {
        for (final nestedId in node.collectIds(includeSelf: false)) {
          AssetPathEntity? nestedPath;
          for (final p in paths) {
            if (p.id == nestedId) {
              nestedPath = p;
              break;
            }
          }
          if (nestedPath == null) continue;
          final nestedCount = await nestedPath.assetCountAsync;
          for (var i = 0; i < nestedCount; i += pageSize) {
            entities.addAll(
              await nestedPath.getAssetListRange(
                start: i,
                end: (i + pageSize).clamp(0, nestedCount),
              ),
            );
          }
        }
      }
    }

    final seen = <String>{};
    final items = <MediaItem>[];
    for (final entity in entities) {
      if (!seen.add(entity.id)) continue;
      _assetCache[entity.id] = entity;
      items.add(
        await _toMediaItem(entity, albumId: path.id, albumName: path.name),
      );
    }
    items.sort((a, b) => b.createDate.compareTo(a.createDate));
    return items;
  }

  @override
  Future<List<MediaItem>> resolveMediaByIds(Iterable<String> ids) async {
    final items = <MediaItem>[];
    for (final id in ids) {
      final entity = await _entity(id);
      if (entity == null) continue;
      items.add(
        await _toMediaItem(
          entity,
          albumId: entity.relativePath ?? '',
          albumName: entity.relativePath?.isNotEmpty == true
              ? entity.relativePath!
              : '系统相册',
        ),
      );
    }
    items.sort((a, b) => b.createDate.compareTo(a.createDate));
    return items;
  }

  Future<MediaItem> _toMediaItem(
    AssetEntity entity, {
    required String albumId,
    required String albumName,
  }) async {
    final fileSize = await entity.fileSize;
    final latlng = await entity.latlngAsync();
    final kind = _kindOf(entity);
    return MediaItem(
      id: entity.id,
      albumId: albumId,
      albumName: albumName,
      kind: kind,
      createDate: entity.createDateTime,
      width: entity.width,
      height: entity.height,
      byteSize: fileSize,
      duration: entity.type == AssetType.video
          ? Duration(seconds: entity.duration)
          : null,
      latitude: latlng?.latitude,
      longitude: latlng?.longitude,
      mimeType: entity.mimeType,
      title: entity.title,
      isFavorite: entity.isFavorite,
      relativePath: entity.relativePath,
    );
  }

  MediaKind _kindOf(AssetEntity entity) {
    if (entity.type == AssetType.video) return MediaKind.video;
    if (entity.isLivePhoto) return MediaKind.livePhoto;
    return MediaKind.image;
  }

  RequestType _toRequestType(RequestFilter filter) {
    switch (filter) {
      case RequestFilter.all:
        return RequestType.common;
      case RequestFilter.images:
        return RequestType.image;
      case RequestFilter.videos:
        return RequestType.video;
      case RequestFilter.livePhotos:
        return RequestType.image;
    }
  }

  Future<AssetEntity?> _entity(String id) async {
    if (_assetCache.containsKey(id)) return _assetCache[id];
    final entity = await AssetEntity.fromId(id);
    if (entity != null) _assetCache[id] = entity;
    return entity;
  }

  @override
  Future<Uint8List?> loadThumbnail(String id, {int size = 400}) async {
    final entity = await _entity(id);
    return entity?.thumbnailDataWithSize(ThumbnailSize(size, size));
  }

  @override
  Future<Uint8List?> loadOriginBytes(String id) async {
    final entity = await _entity(id);
    return entity?.originBytes;
  }

  @override
  Future<String?> loadPlayableVideoPath(String id) async {
    final entity = await _entity(id);
    if (entity == null || entity.type != AssetType.video) return null;
    final file = await entity.file;
    return file?.path;
  }

  @override
  Future<ui.Image?> loadUiImage(String id, {int? maxSize}) async {
    final bytes = maxSize == null
        ? await loadOriginBytes(id)
        : await loadThumbnail(id, size: maxSize);
    if (bytes == null) return null;
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: maxSize);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Future<bool> deleteMedia(List<String> ids) async {
    if (ids.isEmpty) return true;
    final result = await PhotoManager.editor.deleteWithIds(ids);
    for (final id in result) {
      _assetCache.remove(id);
    }
    return result.length == ids.length;
  }

  @override
  ImageProvider? imageProvider(MediaItem item, {int thumbSize = 800}) {
    final entity = _assetCache[item.id];
    if (entity == null) return null;
    return AssetEntityImageProvider(
      entity,
      isOriginal: false,
      thumbnailSize: ThumbnailSize(thumbSize, thumbSize),
    );
  }
}
