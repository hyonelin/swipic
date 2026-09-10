import 'package:flutter/foundation.dart';

import 'media_item.dart';

enum DuplicateKind { exact, similar }

enum KeepStrategy {
  clearest,
  largest,
  smallest,
  newest,
  oldest,
  inAlbum,
}

@immutable
class DuplicateGroup {
  const DuplicateGroup({
    required this.id,
    required this.kind,
    required this.items,
    this.similarity = 1.0,
  });

  final String id;
  final DuplicateKind kind;
  final List<MediaItem> items;
  final double similarity;

  int get count => items.length;

  int get potentialSaveBytes {
    if (items.length < 2) return 0;
    final sorted = [...items]..sort((a, b) => b.byteSize.compareTo(a.byteSize));
    return sorted.skip(1).fold<int>(0, (sum, item) => sum + item.byteSize);
  }

  MediaItem? suggestKeep(KeepStrategy strategy, {String? preferredAlbumId}) {
    if (items.isEmpty) return null;
    switch (strategy) {
      case KeepStrategy.clearest:
        return items.reduce(
          (a, b) => a.sharpnessScore >= b.sharpnessScore ? a : b,
        );
      case KeepStrategy.largest:
        return items.reduce((a, b) => a.byteSize >= b.byteSize ? a : b);
      case KeepStrategy.smallest:
        return items.reduce((a, b) => a.byteSize <= b.byteSize ? a : b);
      case KeepStrategy.newest:
        return items.reduce(
          (a, b) => a.createDate.isAfter(b.createDate) ? a : b,
        );
      case KeepStrategy.oldest:
        return items.reduce(
          (a, b) => a.createDate.isBefore(b.createDate) ? a : b,
        );
      case KeepStrategy.inAlbum:
        if (preferredAlbumId == null) return items.first;
        return items.firstWhere(
          (item) => item.albumId == preferredAlbumId,
          orElse: () => items.first,
        );
    }
  }

  Set<String> idsToDelete(KeepStrategy strategy, {String? preferredAlbumId}) {
    final keep = suggestKeep(strategy, preferredAlbumId: preferredAlbumId);
    if (keep == null) return {};
    return items.where((item) => item.id != keep.id).map((e) => e.id).toSet();
  }
}
