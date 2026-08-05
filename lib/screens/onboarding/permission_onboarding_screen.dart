import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';

class PermissionOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionOnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState
    extends ConsumerState<PermissionOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    await ref.read(permissionStateProvider.notifier).requestAll();
    // Demo mode platforms still complete onboarding.
    if (ref.read(useDemoLibraryProvider)) {
      await ref.read(permissionServiceProvider).markOnboardingComplete();
    }
    setState(() => _requesting = false);

    final state = ref.read(permissionStateProvider);
    if (state == AppPermissionState.denied ||
        state == AppPermissionState.permanentlyDenied) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('需要照片权限'),
          content: const Text(
            'Swipic 需要访问相册才能清理照片。你可以在系统设置中重新开启。',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(permissionStateProvider.notifier).openSettings();
              },
              child: const Text('打开设置'),
            ),
          ],
        ),
      );
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _intro,
                    curve: Curves.easeOutCubic,
                  )),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Swipic',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          color: AppColors.label,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '左右滑动，清理相册。\n全程离线，照片只留在你的设备上。',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: AppColors.secondaryLabel,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const _PermRow(
                  icon: CupertinoIcons.photo_on_rectangle,
                  title: '照片与视频',
                  subtitle: '浏览相册、实况照片和视频',
                ),
                const SizedBox(height: 14),
                const _PermRow(
                  icon: CupertinoIcons.location,
                  title: '媒体位置信息',
                  subtitle: '用于展示 EXIF 中的拍摄地点（可选）',
                ),
                const SizedBox(height: 14),
                const _PermRow(
                  icon: CupertinoIcons.lock_shield,
                  title: '不联网',
                  subtitle: '应用不申请网络权限，分析都在本地完成',
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _requesting ? null : _request,
                    child: _requesting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            '继续并授权',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '首次启动会一次性请求所需权限',
                    style: TextStyle(
                      color: AppColors.tertiaryLabel,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
