import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.highQuality = false,
    this.showBadges = true,
  });

  final MediaItem item;
  final BoxFit fit;
  final bool highQuality;
  final bool showBadges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(mediaLibraryProvider);
    final provider = library.imageProvider(
      item,
      thumbSize: highQuality ? 960 : 320,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.surfaceSecondary,
          child: provider == null
              ? const Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    color: AppColors.tertiaryLabel,
                  ),
                )
              : Image(
                  image: provider,
                  fit: fit,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: AppColors.tertiaryLabel,
                    ),
                  ),
                ),
        ),
        if (showBadges) ...[
          if (item.isLivePhoto)
            const Positioned(
              top: 8,
              left: 8,
              child: _Badge(icon: CupertinoIcons.circle, label: '实况'),
            ),
          if (item.isVideo)
            Positioned(
              right: 8,
              bottom: 8,
              child: _Badge(
                icon: CupertinoIcons.play_fill,
                label: _formatDuration(item.duration),
              ),
            ),
        ],
      ],
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '视频';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
