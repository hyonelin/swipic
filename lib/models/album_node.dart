import 'package:flutter/foundation.dart';

/// Tree node for albums / folders, including nested album-in-album cases.
@immutable
class AlbumNode {
  const AlbumNode({
    required this.id,
    required this.name,
    required this.assetCount,
    this.parentId,
    this.children = const [],
    this.isAll = false,
    this.isSmart = false,
    this.depth = 0,
  });

  final String id;
  final String name;
  final int assetCount;
  final String? parentId;
  final List<AlbumNode> children;
  final bool isAll;
  final bool isSmart;
  final int depth;

  bool get hasChildren => children.isNotEmpty;

  AlbumNode copyWith({
    List<AlbumNode>? children,
    int? assetCount,
    int? depth,
  }) {
    return AlbumNode(
      id: id,
      name: name,
      assetCount: assetCount ?? this.assetCount,
      parentId: parentId,
      children: children ?? this.children,
      isAll: isAll,
      isSmart: isSmart,
      depth: depth ?? this.depth,
    );
  }

  /// Flatten nested albums for search / recursive selection.
  List<AlbumNode> flatten() {
    final result = <AlbumNode>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  /// Collect this album and all descendant ids (nested albums).
  Set<String> collectIds({bool includeSelf = true}) {
    final ids = <String>{};
    if (includeSelf) ids.add(id);
    for (final child in children) {
      ids.addAll(child.collectIds());
    }
    return ids;
  }
}
