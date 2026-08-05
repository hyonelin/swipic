import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/album_node.dart';
import '../../models/duplicate_group.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_thumbnail.dart';
import 'duplicate_group_screen.dart';

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  String? _albumId;
  String _albumName = '所有照片';
  KeepStrategy _strategy = KeepStrategy.clearest;
  String? _preferredAlbumId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final albums = ref.read(albumTreeProvider).valueOrNull;
      if (albums != null && albums.isNotEmpty) {
        final all = albums.firstWhere(
          (a) => a.isAll,
          orElse: () => albums.first,
        );
        setState(() {
          _albumId = all.id;
          _albumName = all.name;
        });
      }
    });
  }

  Future<void> _pickAlbum() async {
    final albums = await ref.read(albumTreeProvider.future);
    final flat = albums.expand((a) => a.flatten()).toList();
    if (!mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择扫描范围'),
        actions: [
          for (final album in flat)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _albumId = album.id;
                  _albumName = album.name;
                });
                Navigator.pop(context);
              },
              child: Text(
                '${'  ' * album.depth}${album.name}（${album.assetCount}）',
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _applyStrategyToAll() async {
    final groups = ref.read(duplicateScanProvider).groups;
    if (groups.isEmpty) return;
    final ids = <String>{};
    for (final group in groups) {
      ids.addAll(
        group.idsToDelete(
          _strategy,
          preferredAlbumId: _preferredAlbumId,
        ),
      );
    }
    await ref.read(pendingDeleteIdsProvider.notifier).markMany(ids);
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('已标记'),
        content: Text('已按策略将 ${ids.length} 张照片加入待删除'),
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
    final scan = ref.watch(duplicateScanProvider);
    final albums = ref.watch(albumTreeProvider).valueOrNull ?? const <AlbumNode>[];
    final flatAlbums = albums.expand((a) => a.flatten()).toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('相似与重复'),
        previousPageTitle: 'Swipic',
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _pickAlbum,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.folder, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '范围：$_albumName',
                            style: const TextStyle(
                              color: AppColors.label,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 16,
                          color: AppColors.secondaryLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '保留策略',
                    style: TextStyle(
                      color: AppColors.secondaryLabel,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in KeepStrategy.values)
                        _StrategyChip(
                          label: _strategyLabel(s),
                          selected: _strategy == s,
                          onTap: () => setState(() => _strategy = s),
                        ),
                    ],
                  ),
                  if (_strategy == KeepStrategy.inAlbum) ...[
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await showCupertinoModalPopup<void>(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            title: const Text('优先保留此相册中的照片'),
                            actions: [
                              for (final album in flatAlbums)
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    setState(() => _preferredAlbumId = album.id);
                                    Navigator.pop(context);
                                  },
                                  child: Text(album.name),
                                ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _preferredAlbumId == null
                            ? '选择优先相册'
                            : '优先：${flatAlbums.firstWhere((a) => a.id == _preferredAlbumId, orElse: () => flatAlbums.first).name}',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      onPressed: scan.scanning || _albumId == null
                          ? null
                          : () => ref
                              .read(duplicateScanProvider.notifier)
                              .scanAlbum(_albumId!),
                      child: scan.scanning
                          ? Text('扫描中 ${(scan.progress * 100).round()}%')
                          : const Text('开始本地扫描'),
                    ),
                  ),
                  if (scan.scanning) ...[
                    const SizedBox(height: 10),
                    CupertinoActivityIndicator(radius: 10),
                  ],
                ],
              ),
            ),
            if (scan.error != null) ...[
              const SizedBox(height: 12),
              Text(
                scan.error!,
                style: const TextStyle(color: AppColors.delete),
              ),
            ],
            if (scan.groups.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${scan.groups.length} 组 · 可释放 ${_formatBytes(scan.groups.fold<int>(0, (s, g) => s + g.potentialSaveBytes))}',
                    style: const TextStyle(
                      color: AppColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _applyStrategyToAll,
                    child: const Text(
                      '按策略标记',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final group in scan.groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupCard(
                    group: group,
                    strategy: _strategy,
                    preferredAlbumId: _preferredAlbumId,
                    onOpen: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => DuplicateGroupScreen(
                            group: group,
                            strategy: _strategy,
                            preferredAlbumId: _preferredAlbumId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ] else if (!scan.scanning && scan.progress == 0) ...[
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  '选择相册后开始扫描\n完全离线，不会上传任何照片',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _strategyLabel(KeepStrategy s) {
    switch (s) {
      case KeepStrategy.clearest:
        return '更清晰';
      case KeepStrategy.largest:
        return '更大';
      case KeepStrategy.smallest:
        return '更小';
      case KeepStrategy.newest:
        return '最新';
      case KeepStrategy.oldest:
        return '最旧';
      case KeepStrategy.inAlbum:
        return '某相册';
    }
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

class _StrategyChip extends StatelessWidget {
  const _StrategyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.separator,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.label,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.strategy,
    required this.onOpen,
    this.preferredAlbumId,
  });

  final DuplicateGroup group;
  final KeepStrategy strategy;
  final String? preferredAlbumId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final keep = group.suggestKeep(strategy, preferredAlbumId: preferredAlbumId);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  group.kind == DuplicateKind.exact ? '完全重复' : '相似照片',
                  style: TextStyle(
                    color: group.kind == DuplicateKind.exact
                        ? AppColors.delete
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.count} 张',
                  style: const TextStyle(
                    color: AppColors.secondaryLabel,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: AppColors.tertiaryLabel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  final isKeep = keep?.id == item.id;
                  return Container(
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isKeep ? AppColors.keep : AppColors.separator,
                        width: isKeep ? 2 : 0.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaThumbnail(item: item, showBadges: false),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
