import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/permission_onboarding_screen.dart';
import 'theme/app_theme.dart';

class SwipicApp extends ConsumerWidget {
  const SwipicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Swipic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material,
      builder: (context, child) {
        return CupertinoTheme(
          data: AppTheme.cupertino,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  bool? _ready;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final done =
        await ref.read(permissionServiceProvider).hasCompletedOnboarding();
    // Skip native permission probes in demo / non-mobile preview environments
    // (PhotoManager may hang when plugins are unavailable).
    if (done && !ref.read(useDemoLibraryProvider)) {
      await ref.read(permissionStateProvider.notifier).refresh();
    }
    if (!mounted) return;
    setState(() => _ready = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready == null) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_ready == false) {
      return PermissionOnboardingScreen(
        onFinished: () => setState(() => _ready = true),
      );
    }

    return const HomeScreen();
  }
}
