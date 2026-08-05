import 'dart:io';

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

  bool get _supportsPhotoManager {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

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
    if (!_supportsPhotoManager) {
      await markOnboardingComplete();
      return AppPermissionState.granted;
    }

    final photo = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: true,
        ),
      ),
    );

    if (Platform.isAndroid) {
      await [
        Permission.photos,
        Permission.videos,
        Permission.storage,
        Permission.accessMediaLocation,
      ].request();
    }

    await markOnboardingComplete();
    return _mapPhotoState(photo);
  }

  Future<AppPermissionState> currentPhotoPermission() async {
    if (!_supportsPhotoManager) return AppPermissionState.granted;

    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    return _mapPhotoState(state);
  }

  Future<bool> openSystemSettings() async {
    if (!_supportsPhotoManager) return false;
    await PhotoManager.openSetting();
    return true;
  }

  AppPermissionState _mapPhotoState(PermissionState state) {
    if (state.isAuth) return AppPermissionState.granted;
    if (state.hasAccess) return AppPermissionState.limited;
    if (state == PermissionState.denied) return AppPermissionState.denied;
    return AppPermissionState.permanentlyDenied;
  }
}
