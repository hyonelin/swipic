import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/media_item.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/zoomable_media.dart';
import 'exif_sheet.dart';

class MediaDetailScreen extends ConsumerWidget {
  const MediaDetailScreen({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingDeleteIdsProvider).contains(item.id);
    final date = DateFormat('yyyy年M月d日 HH:mm').format(item.createDate);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.7),
        middle: Text(
          item.isLivePhoto
              ? '实况照片'
              : item.isVideo
                  ? '视频'
                  : '照片',
          style: const TextStyle(color: CupertinoColors.white),
        ),
        previousPageTitle: '返回',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showExifSheet(context, item),
          child: const Text(
            'EXIF',
            style: TextStyle(color: CupertinoColors.white),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: ZoomableMedia(item: item)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              color: CupertinoColors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.width}×${item.height} · ${_formatBytes(item.byteSize)} · ${item.albumName}',
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: pending
                              ? AppColors.keep
                              : AppColors.delete.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () async {
                            final notifier =
                                ref.read(pendingDeleteIdsProvider.notifier);
                            if (pending) {
                              await notifier.unmark(item.id);
                            } else {
                              await notifier.mark(item.id);
                            }
                          },
                          child: Text(
                            pending ? '从待删除恢复' : '标记删除',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        onPressed: () => showExifSheet(context, item),
                        child: const Text(
                          '信息',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
