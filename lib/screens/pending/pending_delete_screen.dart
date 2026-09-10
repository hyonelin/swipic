import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_item.dart';
import '../../providers/app_providers.dart';
import '../../services/media_library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_thumbnail.dart';
import '../detail/media_detail_screen.dart';

class PendingDeleteScreen extends ConsumerStatefulWidget {
  const PendingDeleteScreen({super.key});

  @override
  ConsumerState<PendingDeleteScreen> createState() =>
      _PendingDeleteScreenState();
}

class _PendingDeleteScreenState extends ConsumerState<PendingDeleteScreen> {
  List<MediaItem>? _items;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final pending = ref.read(pendingDeleteIdsProvider);
    final library = ref.read(mediaLibraryProvider);
    final all = await library.loadAllMedia();
    final byId = {for (final item in all) item.id: item};
    final resolved =
        pending.map((id) => byId[id]).whereType<MediaItem>().toList();

    if (!mounted) return;
    setState(() {
      _items = resolved;
      _loading = false;
    });
  }

  Future<void> _confirmDelete() async {
    final items = _items;
    if (items == null || items.isEmpty) return;

    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('删除 ${items.length} 项？'),
        content: const Text(
          '将从系统相册中永久删除这些照片/视频。此操作不可撤销。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    final ids = items.map((e) => e.id).toList();
    var deleted = false;
    try {
      deleted = await ref.read(mediaLibraryProvider).deleteMedia(ids);
      if (deleted) {
        await ref.read(pendingDeleteIdsProvider.notifier).unmarkMany(ids);
        ref.invalidate(albumTreeProvider);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    await _reload();
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(deleted ? '已删除' : '删除失败'),
        content: Text(
          deleted
              ? '已删除 ${ids.length} 项'
              : '系统相册没有确认删除这些项目，已保留在待删除列表中。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? const <MediaItem>[];
    final bytes = items.fold<int>(0, (sum, e) => sum + e.byteSize);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('待删除'),
        previousPageTitle: '返回',
        trailing: items.isEmpty
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _deleting ? null : _confirmDelete,
                child: Text(
                  _deleting ? '删除中…' : '确认删除',
                  style: const TextStyle(color: AppColors.delete),
                ),
              ),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    '暂无待删除照片',
                    style: TextStyle(color: AppColors.secondaryLabel),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            '${items.length} 项 · 可释放 ${_formatBytes(bytes)}',
                            style: const TextStyle(
                              color: AppColors.secondaryLabel,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await ref
                                  .read(pendingDeleteIdsProvider.notifier)
                                  .clear();
                              await _reload();
                            },
                            child: const Text(
                              '全部恢复',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => MediaDetailScreen(item: item),
                                ),
                              );
                            },
                            onLongPress: () async {
                              await ref
                                  .read(pendingDeleteIdsProvider.notifier)
                                  .unmark(item.id);
                              await _reload();
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  MediaThumbnail(item: item),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.delete,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        CupertinoIcons.xmark,
                                        size: 10,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
