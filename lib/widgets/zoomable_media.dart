import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'video_controller_factory.dart';

class ZoomableMedia extends ConsumerStatefulWidget {
  const ZoomableMedia({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<ZoomableMedia> createState() => _ZoomableMediaState();
}

class _ZoomableMediaState extends ConsumerState<ZoomableMedia>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _animation;
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _livePlaying = false;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          if (_animation != null) {
            _controller.value = _animation!.value;
          }
        });
    if (widget.item.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final library = ref.read(mediaLibraryProvider);
      final path = await library.loadPlayableVideoPath(widget.item.id);
      final video = createVideoPlayerController(path);
      if (video == null) return;
      await video.initialize();
      video.addListener(_onVideoChanged);
      if (!mounted) {
        await video.dispose();
        return;
      }
      setState(() {
        _video = video;
        _videoReady = true;
      });
    } catch (_) {
      // Keep the detail view usable even when the platform cannot expose a file.
    }
  }

  void _onVideoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoChanged);
    _anim.dispose();
    _controller.dispose();
    _video?.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final current = _controller.value.getMaxScaleOnAxis();
    final target = current > 1.05
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(2.5, 2.5, 1);
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(mediaLibraryProvider);
    final provider = library.imageProvider(widget.item, thumbSize: 1200);
    final video = _video;

    return GestureDetector(
      onTap: widget.item.isVideo && _videoReady
          ? () async {
              if (video == null) return;
              if (video.value.isPlaying) {
                await video.pause();
              } else {
                await video.play();
              }
            }
          : null,
      onDoubleTap: _onDoubleTap,
      onLongPressStart: widget.item.isLivePhoto
          ? (_) => setState(() => _livePlaying = true)
          : null,
      onLongPressEnd: widget.item.isLivePhoto
          ? (_) => setState(() => _livePlaying = false)
          : null,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (provider != null)
              AnimatedOpacity(
                opacity: _livePlaying ? 0.85 : 1,
                duration: const Duration(milliseconds: 180),
                child: Image(image: provider, fit: BoxFit.contain),
              )
            else
              const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  color: AppColors.tertiaryLabel,
                  size: 48,
                ),
              ),
            if (video != null && _videoReady)
              Center(
                child: AspectRatio(
                  aspectRatio: video.value.aspectRatio == 0
                      ? 1
                      : video.value.aspectRatio,
                  child: VideoPlayer(video),
                ),
              ),
            if (widget.item.isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoReady && video?.value.isPlaying == true
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            if (widget.item.isLivePhoto)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _livePlaying
                            ? CupertinoIcons.pause_circle
                            : CupertinoIcons.circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _livePlaying ? '播放实况' : '长按查看实况',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
