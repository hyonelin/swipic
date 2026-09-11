import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/app_providers.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_list_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(useDemoLibraryProvider);
    final permission = ref.watch(permissionStateProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('设置'),
        previousPageTitle: 'Swipic',
      ),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          IosGroup(
            header: '权限',
            footer: '所有权限应在首次启动时申请。若曾拒绝，可在此前往系统设置。',
            children: [
              IosListTile(
                leading: const IosIconBubble(
                  icon: CupertinoIcons.photo,
                  color: AppColors.accent,
                ),
                title: '照片权限',
                subtitle: _permissionLabel(permission),
                showChevron: true,
                onTap: () async {
                  await ref.read(permissionStateProvider.notifier).refresh();
                  final state = ref.read(permissionStateProvider);
                  if (state == AppPermissionState.granted ||
                      state == AppPermissionState.limited) {
                    return;
                  }
                  await ref
                      .read(permissionStateProvider.notifier)
                      .openSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          IosGroup(
            header: '外观',
            footer: '深色模式会自动跟随系统设置；如需切换，请在 Android / iOS 系统外观设置中修改。',
            children: const [
              IosListTile(
                leading: IosIconBubble(
                  icon: CupertinoIcons.moon_stars_fill,
                  color: Color(0xFF5856D6),
                ),
                title: '深色模式',
                subtitle: '跟随系统',
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          IosGroup(
            header: '图库来源',
            footer:
                '真机请关闭演示模式以访问系统相册。演示图库数据在 lib/services/demo_library_service.dart 中维护，适合后续手动调整示例照片、相册和重复项。',
            children: [
              IosListTile(
                leading: const IosIconBubble(
                  icon: CupertinoIcons.cube,
                  color: AppColors.warning,
                ),
                title: '演示模式',
                subtitle: demo ? '使用内置示例相册' : '使用设备相册',
                showChevron: false,
                trailing: CupertinoSwitch(
                  value: demo,
                  onChanged: (value) {
                    ref.read(useDemoLibraryProvider.notifier).state = value;
                    ref.invalidate(albumTreeProvider);
                  },
                ),
              ),
              IosListTile(
                leading: const IosIconBubble(
                  icon: CupertinoIcons.doc_text_fill,
                  color: AppColors.accent,
                ),
                title: '如何调整演示照片',
                subtitle: '查看 docs/DEMO_LIBRARY.md',
                showChevron: false,
                onTap: () => _showDemoGuide(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IosGroup(
            header: '隐私',
            children: [
              const IosListTile(
                leading: IosIconBubble(
                  icon: CupertinoIcons.lock_shield_fill,
                  color: AppColors.keep,
                ),
                title: '完全离线',
                subtitle: '不申请网络权限，分析与查重均在本地完成',
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          IosGroup(
            header: '关于盈利（建议）',
            footer: '因应用坚持不索取网络权限，最契合的方式是付费下载或一次性解锁 Pro。订阅通常需要联网校验，会与“全程离线”冲突。',
            children: [
              IosListTile(
                leading: const IosIconBubble(
                  icon: CupertinoIcons.money_yen_circle_fill,
                  color: Color(0xFF5856D6),
                ),
                title: '推荐：付费下载',
                subtitle: 'App Store / Play 一次性买断，应用本身零联网',
                showChevron: false,
                onTap: () => _showMonetization(context),
              ),
              IosListTile(
                leading: const IosIconBubble(
                  icon: CupertinoIcons.star_circle_fill,
                  color: AppColors.warning,
                ),
                title: '备选：本地功能分层',
                subtitle: '免费：每日清理额度；买断解锁无限查重',
                showChevron: false,
                onTap: () => _showMonetization(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final label = info == null
                    ? 'Swipic 1.0.4'
                    : 'Swipic ${info.version} (${info.buildNumber})';
                return Text(
                  label,
                  style: TextStyle(
                    color: AppColors.resolve(context, AppColors.tertiaryLabel),
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _permissionLabel(AppPermissionState state) {
    switch (state) {
      case AppPermissionState.unknown:
        return '尚未检查';
      case AppPermissionState.granted:
        return '已授权';
      case AppPermissionState.limited:
        return '有限访问';
      case AppPermissionState.denied:
        return '已拒绝';
      case AppPermissionState.permanentlyDenied:
        return '需在设置中开启';
    }
  }

  void _showMonetization(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('离线友好的盈利方式'),
        content: const Text(
          '1. 付费下载（推荐）：商店完成收款，应用不声明网络权限。\n'
          '2. 一次性 Pro 解锁：购买时走系统商店，应用可不声明 INTERNET。\n'
          '3. 避免订阅与云同步：它们依赖持续联网，与产品定位冲突。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showDemoGuide(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('调整演示图库'),
        content: const Text(
          '演示照片由 lib/services/demo_library_service.dart 生成。\n\n'
          '常改位置：\n'
          '1. _seed()：增删相册、照片、视频、Live Photo。\n'
          '2. _makeItem()：调整标题、日期、尺寸、体积、类型。\n'
          '3. cloneFrom / similarTo：制造重复或相似照片。\n\n'
          '更完整说明见 docs/DEMO_LIBRARY.md。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
