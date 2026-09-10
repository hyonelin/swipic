import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/cleanup_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/swipe_card.dart';
import '../detail/media_detail_screen.dart';
import '../pending/pending_delete_screen.dart';

class SwipeCleanupScreen extends ConsumerWidget {
  const SwipeCleanupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(cleanupSessionProvider);
    final pendingCount = ref.watch(pendingDeleteIdsProvider).length;

    if (session == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('清理')),
        child: Center(child: Text('没有清理会话')),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(session.albumName),
        previousPageTitle: '相册',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const PendingDeleteScreen()),
            );
          },
          child: Text(
            pendingCount == 0 ? '待删除' : '待删除 ($pendingCount)',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
      child: SafeArea(
        child: session.isFinished
            ? _FinishedView(
                kept: session.kept.length,
                deleted: session.history
                    .where((d) => d == SwipeDecision.delete)
                    .length,
                onPending: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const PendingDeleteScreen(),
                    ),
                  );
                },
                onDone: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          '剩余 ${session.remaining}',
                          style: const TextStyle(
                            color: AppColors.secondaryLabel,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: session.history.isEmpty
                              ? null
                              : () => ref
                                  .read(cleanupSessionProvider.notifier)
                                  .undo(),
                          child: const Text('撤销'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: SwipeCard(
                        key: ValueKey(session.current!.id),
                        item: session.current!,
                        onDecision: (keep) {
                          ref.read(cleanupSessionProvider.notifier).decide(
                                keep
                                    ? SwipeDecision.keep
                                    : SwipeDecision.delete,
                              );
                        },
                        onOpenDetail: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) =>
                                  MediaDetailScreen(item: session.current!),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RoundAction(
                          color: AppColors.delete,
                          icon: CupertinoIcons.xmark,
                          label: '删除',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(cleanupSessionProvider.notifier)
                                .decide(SwipeDecision.delete);
                          },
                        ),
                        _RoundAction(
                          color: AppColors.secondaryLabel,
                          icon: CupertinoIcons.info,
                          label: '详情',
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) =>
                                    MediaDetailScreen(item: session.current!),
                              ),
                            );
                          },
                        ),
                        _RoundAction(
                          color: AppColors.keep,
                          icon: CupertinoIcons.heart_fill,
                          label: '保留',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(cleanupSessionProvider.notifier)
                                .decide(SwipeDecision.keep);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.kept,
    required this.deleted,
    required this.onPending,
    required this.onDone,
  });

  final int kept;
  final int deleted;
  final VoidCallback onPending;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.checkmark_seal, size: 64, color: AppColors.keep),
          const SizedBox(height: 18),
          const Text(
            '本轮清理完成',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '保留 $kept · 标记删除 $deleted',
            style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '删除尚未执行，可在「待删除」中确认',
            style: TextStyle(color: AppColors.tertiaryLabel, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: onPending,
              child: const Text('查看待删除'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: onDone,
              child: const Text('返回'),
            ),
          ),
        ],
      ),
    );
  }
}
