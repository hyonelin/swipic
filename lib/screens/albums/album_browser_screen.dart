import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/album_node.dart';
import '../../providers/app_providers.dart';
import '../../providers/cleanup_controller.dart';
import '../../theme/app_theme.dart';
import '../swipe/swipe_cleanup_screen.dart';

class AlbumBrowserScreen extends ConsumerWidget {
  const AlbumBrowserScreen({super.key, this.parent});

  final AlbumNode? parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumTreeProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(parent?.name ?? '相册'),
        previousPageTitle: parent == null ? 'Swipic' : '相册',
      ),
      child: albumsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (roots) {
          final nodes = parent?.children ?? roots;
          if (nodes.isEmpty) {
            return const Center(
              child: Text(
                '没有相册',
                style: TextStyle(color: AppColors.secondaryLabel),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: nodes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final node = nodes[index];
              return _AlbumRow(
                node: node,
                onOpenChildren: node.hasChildren
                    ? () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => AlbumBrowserScreen(parent: node),
                          ),
                        );
                      }
                    : null,
                onClean: () => _startCleanup(context, ref, node),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startCleanup(
    BuildContext context,
    WidgetRef ref,
    AlbumNode node,
  ) async {
    await ref.read(cleanupSessionProvider.notifier).start(
          albumId: node.id,
          albumName: node.name,
        );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const SwipeCleanupScreen()),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({
    required this.node,
    required this.onClean,
    this.onOpenChildren,
  });

  final AlbumNode node;
  final VoidCallback onClean;
  final VoidCallback? onOpenChildren;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            onPressed: onClean,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    node.isAll
                        ? CupertinoIcons.photo_fill_on_rectangle_fill
                        : node.hasChildren
                            ? CupertinoIcons.folder_fill
                            : CupertinoIcons.rectangle_stack_fill,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        node.hasChildren
                            ? '${node.assetCount} 项 · 含 ${node.children.length} 个子相册'
                            : '${node.assetCount} 项',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '清理',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onOpenChildren != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  minimumSize: Size.zero,
                  onPressed: onOpenChildren,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.folder, size: 16, color: AppColors.accent),
                      SizedBox(width: 6),
                      Text(
                        '查看子相册',
                        style: TextStyle(fontSize: 14, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
