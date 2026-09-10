import 'dart:typed_data';

import 'package:exif/exif.dart';

import '../models/exif_info.dart';
import '../models/media_item.dart';
import 'media_library_service.dart';

class ExifService {
  ExifService(this._library);

  final MediaLibraryService _library;

  Future<ExifInfo> loadFor(MediaItem item) async {
    if (item.isVideo) {
      return ExifInfo(
        dateTimeOriginal: item.createDate.toIso8601String(),
        width: item.width,
        height: item.height,
        latitude: item.latitude,
        longitude: item.longitude,
        raw: {
          '类型': '视频',
          '时长': _formatDuration(item.duration),
          '大小': _formatBytes(item.byteSize),
          if (item.mimeType != null) 'MIME': item.mimeType!,
        },
      );
    }

    final bytes = await _library.loadOriginBytes(item.id);
    if (bytes == null || bytes.isEmpty) {
      return ExifInfo(
        dateTimeOriginal: item.createDate.toIso8601String(),
        width: item.width,
        height: item.height,
        latitude: item.latitude,
        longitude: item.longitude,
      );
    }

    return parseBytes(bytes, fallback: item);
  }

  Future<ExifInfo> parseBytes(Uint8List bytes, {MediaItem? fallback}) async {
    try {
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) {
        return ExifInfo(
          dateTimeOriginal: fallback?.createDate.toIso8601String(),
          width: fallback?.width,
          height: fallback?.height,
          latitude: fallback?.latitude,
          longitude: fallback?.longitude,
        );
      }

      String? str(String key) {
        final tag = data[key];
        if (tag == null) return null;
        return tag.printable.trim();
      }

      final lat = _gpsCoordinate(
        data['GPS GPSLatitude'],
        data['GPS GPSLatitudeRef'],
      );
      final lng = _gpsCoordinate(
        data['GPS GPSLongitude'],
        data['GPS GPSLongitudeRef'],
      );

      final raw = <String, String>{};
      for (final entry in data.entries) {
        raw[entry.key] = entry.value.printable;
      }

      return ExifInfo(
        make: str('Image Make'),
        model: str('Image Model'),
        software: str('Image Software'),
        dateTimeOriginal:
            str('EXIF DateTimeOriginal') ?? str('Image DateTime'),
        exposureTime: str('EXIF ExposureTime'),
        fNumber: str('EXIF FNumber'),
        iso: str('EXIF ISOSpeedRatings'),
        focalLength: str('EXIF FocalLength'),
        lensModel: str('EXIF LensModel'),
        latitude: lat ?? fallback?.latitude,
        longitude: lng ?? fallback?.longitude,
        orientation: str('Image Orientation'),
        width: int.tryParse(str('EXIF ExifImageWidth') ?? '') ??
            fallback?.width,
        height: int.tryParse(str('EXIF ExifImageLength') ?? '') ??
            fallback?.height,
        flash: str('EXIF Flash'),
        whiteBalance: str('EXIF WhiteBalance'),
        raw: raw,
      );
    } catch (_) {
      return ExifInfo(
        dateTimeOriginal: fallback?.createDate.toIso8601String(),
        width: fallback?.width,
        height: fallback?.height,
        latitude: fallback?.latitude,
        longitude: fallback?.longitude,
      );
    }
  }

  double? _gpsCoordinate(IfdTag? values, IfdTag? ref) {
    if (values == null) return null;
    try {
      final parts = values.values.toList();
      if (parts.length < 3) return null;
      final deg = _ratio(parts[0]);
      final min = _ratio(parts[1]);
      final sec = _ratio(parts[2]);
      var result = deg + (min / 60) + (sec / 3600);
      final refStr = ref?.printable ?? '';
      if (refStr == 'S' || refStr == 'W') result = -result;
      return result;
    } catch (_) {
      return null;
    }
  }

  double _ratio(dynamic value) {
    if (value is Ratio) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '-';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
