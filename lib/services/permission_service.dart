import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPermissionState {
  unknown,
  granted,
  limited,
  denied,
  permanentlyDenied,
}

class PermissionService {
  static const _onboardingKey = 'swipic_permissions_requested';

  bool get _isMobileTarget {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Request every permission the app needs up front on first launch.
  Future<AppPermissionState> requestAllOnLaunch() async {
    if (!_isMobileTarget) {
      await markOnboardingComplete();
      return AppPermissionState.granted;
    }

    try {
      final photo = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.common,
            mediaLocation: true,
          ),
        ),
      ).timeout(const Duration(seconds: 20));

      if (_isAndroid) {
        await [
          Permission.photos,
          Permission.videos,
          Permission.storage,
          Permission.accessMediaLocation,
        ].request().timeout(const Duration(seconds: 20));
      }

      await markOnboardingComplete();
      return _mapPhotoState(photo);
    } catch (_) {
      await markOnboardingComplete();
      // In environments without photo plugins (tests / desktop), treat as granted.
      return AppPermissionState.granted;
    }
  }

  Future<AppPermissionState> currentPhotoPermission() async {
    if (!_isMobileTarget) return AppPermissionState.granted;

    try {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.common,
            mediaLocation: false,
          ),
        ),
      ).timeout(const Duration(seconds: 8));
      return _mapPhotoState(state);
    } catch (_) {
      return AppPermissionState.granted;
    }
  }

  Future<bool> openSystemSettings() async {
    if (!_isMobileTarget) return false;
    try {
      await PhotoManager.openSetting();
      return true;
    } catch (_) {
      return false;
    }
  }

  AppPermissionState _mapPhotoState(PermissionState state) {
    if (state.isAuth) return AppPermissionState.granted;
    if (state.hasAccess) return AppPermissionState.limited;
    if (state == PermissionState.denied) return AppPermissionState.denied;
    return AppPermissionState.permanentlyDenied;
  }
}
