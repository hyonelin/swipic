import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_list_tile.dart';
import '../albums/album_browser_screen.dart';
import '../duplicates/duplicates_screen.dart';
import '../pending/pending_delete_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingDeleteIdsProvider);
    final albumsAsync = ref.watch(albumTreeProvider);
    final demo = ref.watch(useDemoLibraryProvider);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Swipic'),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _HeroBanner(
                subtitle: demo
                    ? '当前为演示图库，可完整体验滑动与查重流程'
                    : '选择相册，左右滑动清理',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: IosGroup(
              header: '开始清理',
              children: [
                IosListTile(
                  leading: const IosIconBubble(
                    icon: CupertinoIcons.collections,
                    color: AppColors.accent,
                  ),
                  title: '相册',
                  subtitle: albumsAsync.maybeWhen(
                    data: (albums) => '${albums.length} 个相册',
                    orElse: () => '浏览文件夹与嵌套相册',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const AlbumBrowserScreen(),
                      ),
                    );
                  },
                ),
                IosListTile(
                  leading: const IosIconBubble(
                    icon: CupertinoIcons.square_stack_3d_up,
                    color: AppColors.warning,
                  ),
                  title: '相似与重复',
                  subtitle: '本地检测，可选保留策略',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const DuplicatesScreen(),
                      ),
                    );
                  },
                ),
                IosListTile(
                  leading: IosIconBubble(
                    icon: CupertinoIcons.trash,
                    color: pending.isEmpty ? AppColors.secondaryLabel : AppColors.delete,
                  ),
                  title: '待删除',
                  subtitle: pending.isEmpty
                      ? '滑动删除的照片会先集中在这里'
                      : '${pending.length} 张待确认',
                  trailing: pending.isEmpty
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.delete,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const PendingDeleteScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: IosGroup(
              header: '更多',
              children: [
                IosListTile(
                  leading: const IosIconBubble(
                    icon: CupertinoIcons.gear,
                    color: AppColors.secondaryLabel,
                  ),
                  title: '设置',
                  subtitle: '权限、演示模式与盈利说明',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F1FF),
            Color(0xFFF7F7FA),
            Color(0xFFEAF8F0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '轻扫整理',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HintChip(color: AppColors.delete, label: '左滑删除'),
              const SizedBox(width: 8),
              _HintChip(color: AppColors.keep, label: '右滑保留'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
