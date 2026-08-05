import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/duplicate_group.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_thumbnail.dart';
import '../detail/media_detail_screen.dart';

class DuplicateGroupScreen extends ConsumerStatefulWidget {
  const DuplicateGroupScreen({
    super.key,
    required this.group,
    required this.strategy,
    this.preferredAlbumId,
  });

  final DuplicateGroup group;
  final KeepStrategy strategy;
  final String? preferredAlbumId;

  @override
  ConsumerState<DuplicateGroupScreen> createState() =>
      _DuplicateGroupScreenState();
}

class _DuplicateGroupScreenState extends ConsumerState<DuplicateGroupScreen> {
  late String _keepId;

  @override
  void initState() {
    super.initState();
    _keepId = widget.group
            .suggestKeep(
              widget.strategy,
              preferredAlbumId: widget.preferredAlbumId,
            )
            ?.id ??
        widget.group.items.first.id;
  }

  Future<void> _markOthers() async {
    final ids = widget.group.items
        .where((e) => e.id != _keepId)
        .map((e) => e.id)
        .toSet();
    await ref.read(pendingDeleteIdsProvider.notifier).markMany(ids);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.group.kind == DuplicateKind.exact ? '重复组' : '相似组',
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _markOthers,
          child: const Text('标记其余'),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: widget.group.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = widget.group.items[index];
          final selected = item.id == _keepId;
          return GestureDetector(
            onTap: () => setState(() => _keepId = item.id),
            onLongPress: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => MediaDetailScreen(item: item),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.keep : AppColors.separator,
                  width: selected ? 2 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: MediaThumbnail(item: item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.albumName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.width}×${item.height}',
                          style: const TextStyle(
                            color: AppColors.secondaryLabel,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatBytes(item.byteSize),
                          style: const TextStyle(
                            color: AppColors.secondaryLabel,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: selected ? AppColors.keep : AppColors.tertiaryLabel,
                  ),
                ],
              ),
            ),
          );
        },
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
