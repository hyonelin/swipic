import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import '../models/duplicate_group.dart';
import '../models/media_item.dart';
import 'media_library_service.dart';

/// Fully offline exact / similar photo detection via content hash + aHash.
class DuplicateService {
  DuplicateService(this._library);

  final MediaLibraryService _library;

  /// Hamming distance threshold for similar images (aHash 64-bit).
  static const int similarThreshold = 8;

  Future<List<DuplicateGroup>> findGroups(
    List<MediaItem> items, {
    void Function(double progress)? onProgress,
  }) async {
    final images = items.where((e) => e.isImage).toList();
    if (images.isEmpty) return [];

    final exactBuckets = <String, List<MediaItem>>{};
    final hashes = <String, int>{}; // mediaId -> aHash

    for (var i = 0; i < images.length; i++) {
      final item = images[i];
      onProgress?.call(i / images.length);

      final thumb = await _library.loadThumbnail(item.id, size: 128);
      if (thumb == null) continue;

      final contentHash = md5.convert(thumb).toString();
      exactBuckets.putIfAbsent(contentHash, () => []).add(item);

      final ahash = _averageHash(thumb);
      if (ahash != null) hashes[item.id] = ahash;
    }

    final groups = <DuplicateGroup>[];
    final consumed = <String>{};

    // Exact groups
    var groupIndex = 0;
    for (final entry in exactBuckets.entries) {
      if (entry.value.length < 2) continue;
      for (final item in entry.value) {
        consumed.add(item.id);
      }
      groups.add(
        DuplicateGroup(
          id: 'exact_${groupIndex++}',
          kind: DuplicateKind.exact,
          items: entry.value,
          similarity: 1.0,
        ),
      );
    }

    // Similar groups via union-find on aHash distance
    final remaining = images.where((e) => !consumed.contains(e.id)).toList();
    final parent = <String, String>{
      for (final item in remaining) item.id: item.id,
    };

    String find(String x) {
      parent.putIfAbsent(x, () => x);
      if (parent[x] != x) parent[x] = find(parent[x]!);
      return parent[x]!;
    }

    void union(String a, String b) {
      final ra = find(a);
      final rb = find(b);
      if (ra != rb) parent[rb] = ra;
    }

    for (var i = 0; i < remaining.length; i++) {
      final a = remaining[i];
      final ha = hashes[a.id];
      if (ha == null) continue;
      for (var j = i + 1; j < remaining.length; j++) {
        final b = remaining[j];
        final hb = hashes[b.id];
        if (hb == null) continue;
        final dist = _hamming(ha, hb);
        if (dist <= similarThreshold) union(a.id, b.id);
      }
      onProgress?.call(0.85 + 0.15 * (i / remaining.length));
    }

    final clusters = <String, List<MediaItem>>{};
    for (final item in remaining) {
      if (!hashes.containsKey(item.id)) continue;
      final root = find(item.id);
      clusters.putIfAbsent(root, () => []).add(item);
    }

    var similarIndex = 0;
    for (final cluster in clusters.values) {
      if (cluster.length < 2) continue;
      // Average pairwise similarity estimate
      var simSum = 0.0;
      var pairs = 0;
      for (var i = 0; i < cluster.length; i++) {
        for (var j = i + 1; j < cluster.length; j++) {
          final d = _hamming(hashes[cluster[i].id]!, hashes[cluster[j].id]!);
          simSum += 1 - (d / 64);
          pairs++;
        }
      }
      groups.add(
        DuplicateGroup(
          id: 'similar_${similarIndex++}',
          kind: DuplicateKind.similar,
          items: cluster,
          similarity: pairs == 0 ? 0.9 : simSum / pairs,
        ),
      );
    }

    groups.sort((a, b) => b.potentialSaveBytes.compareTo(a.potentialSaveBytes));
    onProgress?.call(1);
    return groups;
  }

  int? _averageHash(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final small = img.copyResize(decoded, width: 8, height: 8);
      var total = 0;
      final grays = List<int>.filled(64, 0);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          final p = small.getPixel(x, y);
          final g = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
          grays[y * 8 + x] = g;
          total += g;
        }
      }
      final avg = total / 64;
      var hash = 0;
      for (var i = 0; i < 64; i++) {
        if (grays[i] >= avg) hash |= (1 << i);
      }
      return hash;
    } catch (_) {
      return null;
    }
  }

  int _hamming(int a, int b) {
    var x = a ^ b;
    var count = 0;
    // Iterate bit positions instead of masking with a 64-bit constant
    // (keeps web/JS compiles happy with safe integers).
    for (var i = 0; i < 64 && x != 0; i++) {
      if ((x & 1) != 0) count++;
      x >>= 1;
    }
    return math.min(count, 64);
  }
}
