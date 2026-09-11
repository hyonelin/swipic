import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController? createVideoPlayerController(String? path) {
  if (path == null || path.isEmpty) return null;
  return VideoPlayerController.file(File(path));
}
