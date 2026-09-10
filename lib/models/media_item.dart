import 'package:flutter/foundation.dart';

enum MediaKind { image, video, livePhoto }

@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.albumId,
    required this.albumName,
    required this.kind,
    required this.createDate,
    required this.width,
    required this.height,
    required this.byteSize,
    this.duration,
    this.latitude,
    this.longitude,
    this.mimeType,
    this.title,
    this.isFavorite = false,
    this.relativePath,
  });

  final String id;
  final String albumId;
  final String albumName;
  final MediaKind kind;
  final DateTime createDate;
  final int width;
  final int height;
  final int byteSize;
  final Duration? duration;
  final double? latitude;
  final double? longitude;
  final String? mimeType;
  final String? title;
  final bool isFavorite;
  final String? relativePath;

  bool get isVideo => kind == MediaKind.video;
  bool get isLivePhoto => kind == MediaKind.livePhoto;
  bool get isImage => kind == MediaKind.image || kind == MediaKind.livePhoto;

  int get megapixels => ((width * height) / 1000000).round();

  double get sharpnessScore {
    // Proxy sharpness: higher resolution + larger file tends to be clearer.
    final resolution = (width * height).toDouble().clamp(1, double.infinity);
    final density = byteSize / resolution;
    return resolution * (0.35 + density.clamp(0.05, 8));
  }

  MediaItem copyWith({
    String? albumId,
    String? albumName,
  }) {
    return MediaItem(
      id: id,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      kind: kind,
      createDate: createDate,
      width: width,
      height: height,
      byteSize: byteSize,
      duration: duration,
      latitude: latitude,
      longitude: longitude,
      mimeType: mimeType,
      title: title,
      isFavorite: isFavorite,
      relativePath: relativePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
