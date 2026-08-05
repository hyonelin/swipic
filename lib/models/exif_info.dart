import 'package:flutter/foundation.dart';

@immutable
class ExifInfo {
  const ExifInfo({
    this.make,
    this.model,
    this.software,
    this.dateTimeOriginal,
    this.exposureTime,
    this.fNumber,
    this.iso,
    this.focalLength,
    this.lensModel,
    this.latitude,
    this.longitude,
    this.orientation,
    this.width,
    this.height,
    this.flash,
    this.whiteBalance,
    this.raw = const {},
  });

  final String? make;
  final String? model;
  final String? software;
  final String? dateTimeOriginal;
  final String? exposureTime;
  final String? fNumber;
  final String? iso;
  final String? focalLength;
  final String? lensModel;
  final double? latitude;
  final double? longitude;
  final String? orientation;
  final int? width;
  final int? height;
  final String? flash;
  final String? whiteBalance;
  final Map<String, String> raw;

  bool get isEmpty =>
      make == null &&
      model == null &&
      dateTimeOriginal == null &&
      exposureTime == null &&
      fNumber == null &&
      iso == null &&
      latitude == null &&
      raw.isEmpty;

  List<ExifRow> get rows {
    final list = <ExifRow>[
      if (make != null) ExifRow('制造商', make!),
      if (model != null) ExifRow('型号', model!),
      if (lensModel != null) ExifRow('镜头', lensModel!),
      if (software != null) ExifRow('软件', software!),
      if (dateTimeOriginal != null) ExifRow('拍摄时间', dateTimeOriginal!),
      if (exposureTime != null) ExifRow('快门', exposureTime!),
      if (fNumber != null) ExifRow('光圈', 'f/$fNumber'),
      if (iso != null) ExifRow('ISO', iso!),
      if (focalLength != null) ExifRow('焦距', '$focalLength mm'),
      if (flash != null) ExifRow('闪光灯', flash!),
      if (whiteBalance != null) ExifRow('白平衡', whiteBalance!),
      if (orientation != null) ExifRow('方向', orientation!),
      if (width != null && height != null)
        ExifRow('尺寸', '$width × $height'),
      if (latitude != null && longitude != null)
        ExifRow('位置', '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'),
    ];
    return list;
  }
}

@immutable
class ExifRow {
  const ExifRow(this.label, this.value);
  final String label;
  final String value;
}
