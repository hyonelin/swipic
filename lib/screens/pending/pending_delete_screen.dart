import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_item.dart';
import '../../providers/app_providers.dart';
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
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _deleting = false;
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final pending = ref.read(pendingDeleteIdsProvider);
    final library = ref.read(mediaLibraryProvider);
    final resolved = await library.resolveMediaByIds(pending);

    if (!mounted) return;
    setState(() {
      _items = resolved;
      _selectedIds.removeWhere((id) => !resolved.any((item) => item.id == id));
      _loading = false;
    });
  }

  Future<void> _restoreIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    await ref.read(pendingDeleteIdsProvider.notifier).unmarkMany(ids);
    if (!mounted) return;
    setState(() {
      _selectedIds.removeAll(ids);
      _items = [
        for (final item in _items ?? const <MediaItem>[])
          if (!ids.contains(item.id)) item,
      ];
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _confirmDelete([List<MediaItem>? targetItems]) async {
    final items = targetItems ?? _items;
    if (items == null || items.isEmpty || _deleting) return;

    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('删除 ${items.length} 项？'),
        content: const Text('将从系统相册中永久删除这些照片/视频。此操作不可撤销。'),
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
        _selectedIds.removeAll(ids);
        if (_selectedIds.isEmpty) _selectionMode = false;
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
          deleted ? '已删除 ${ids.length} 项' : '系统相册没有确认删除这些项目，已保留在待删除列表中。',
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
    final selectedItems = items
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    final bytes = items.fold<int>(0, (sum, e) => sum + e.byteSize);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_selectionMode ? '已选择 ${_selectedIds.length} 项' : '待删除'),
        previousPageTitle: '返回',
        trailing: items.isEmpty
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _deleting
                    ? null
                    : () {
                        setState(() {
                          _selectionMode = !_selectionMode;
                          if (!_selectionMode) _selectedIds.clear();
                        });
                      },
                child: Text(
                  _selectionMode ? '取消' : '选择',
                  style: const TextStyle(fontSize: 15),
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
                          if (_selectionMode) {
                            setState(() {
                              if (_selectedIds.length == items.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds
                                  ..clear()
                                  ..addAll(items.map((item) => item.id));
                              }
                            });
                          } else {
                            await _restoreIds(items.map((e) => e.id).toSet());
                          }
                        },
                        child: Text(
                          _selectionMode
                              ? _selectedIds.length == items.length
                                    ? '清空选择'
                                    : '全选'
                              : '全部恢复',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      if (!_selectionMode) ...[
                        const SizedBox(width: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _deleting ? null : () => _confirmDelete(),
                          child: Text(
                            _deleting ? '删除中…' : '全部删除',
                            style: const TextStyle(
                              color: AppColors.delete,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
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
                      final selected = _selectedIds.contains(item.id);
                      return GestureDetector(
                        onTap: () async {
                          if (_selectionMode) {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(item.id);
                              } else {
                                _selectedIds.add(item.id);
                              }
                            });
                            return;
                          }
                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => MediaDetailScreen(item: item),
                            ),
                          );
                          if (context.mounted) await _reload();
                        },
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            if (selected) {
                              _selectedIds.remove(item.id);
                            } else {
                              _selectedIds.add(item.id);
                            }
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaThumbnail(item: item),
                              if (selected)
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.black.withValues(
                                        alpha: 0.42,
                                      ),
                                      border: Border.all(
                                        color: AppColors.keep,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.keep
                                        : AppColors.delete,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    selected
                                        ? CupertinoIcons.checkmark
                                        : CupertinoIcons.xmark,
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
                if (_selectionMode)
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.separator),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppColors.keep,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _selectedIds.isEmpty
                                  ? null
                                  : () => _restoreIds(Set.of(_selectedIds)),
                              child: const Text(
                                '恢复所选',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppColors.delete,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _deleting || _selectedIds.isEmpty
                                  ? null
                                  : () => _confirmDelete(selectedItems),
                              child: Text(
                                _deleting ? '删除中…' : '删除所选',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
