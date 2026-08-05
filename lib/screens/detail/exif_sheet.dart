import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_item.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

Future<void> showExifSheet(BuildContext context, MediaItem item) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => ExifSheet(item: item),
  );
}

class ExifSheet extends ConsumerWidget {
  const ExifSheet({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exifAsync = ref.watch(exifProvider(item));

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.separator,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Text(
                  '照片信息',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: AppColors.tertiaryLabel),
                ),
              ],
            ),
          ),
          Expanded(
            child: exifAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('读取失败：$e')),
              data: (info) {
                final rows = info.rows;
                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      '没有可用的 EXIF 信息',
                      style: TextStyle(color: AppColors.secondaryLabel),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      rows[i].label,
                                      style: const TextStyle(
                                        color: AppColors.secondaryLabel,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      rows[i].value,
                                      style: const TextStyle(
                                        color: AppColors.label,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i != rows.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: ColoredBox(
                                  color: AppColors.separator,
                                  child: SizedBox(height: 0.5, width: double.infinity),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (info.raw.length > rows.length) ...[
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          '全部字段',
                          style: TextStyle(
                            color: AppColors.secondaryLabel,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (final entry in info.raw.entries.take(40))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: AppColors.secondaryLabel,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          color: AppColors.label,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
