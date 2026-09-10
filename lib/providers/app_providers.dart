import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album_node.dart';
import '../models/duplicate_group.dart';
import '../models/exif_info.dart';
import '../models/media_item.dart';
import '../services/demo_library_service.dart';
import '../services/duplicate_service.dart';
import '../services/exif_service.dart';
import '../services/media_library_service.dart';
import '../services/pending_delete_service.dart';
import '../services/permission_service.dart';
import '../services/photo_manager_library_service.dart';

final permissionServiceProvider = Provider((ref) => PermissionService());
final pendingDeleteServiceProvider =
    Provider((ref) => PendingDeleteService());

/// Use demo library on desktop / web where PhotoKit & MediaStore are unavailable.
final useDemoLibraryProvider = StateProvider<bool>((ref) {
  if (kIsWeb) return true;
  // Mobile targets only; desktop preview uses the offline demo library.
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return false;
    default:
      return true;
  }
});

final mediaLibraryProvider = Provider<MediaLibraryService>((ref) {
  final demo = ref.watch(useDemoLibraryProvider);
  if (demo) return DemoLibraryService();
  return PhotoManagerLibraryService();
});

final exifServiceProvider = Provider((ref) {
  return ExifService(ref.watch(mediaLibraryProvider));
});

final duplicateServiceProvider = Provider((ref) {
  return DuplicateService(ref.watch(mediaLibraryProvider));
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return ref.watch(permissionServiceProvider).hasCompletedOnboarding();
});

final permissionStateProvider =
    StateNotifierProvider<PermissionController, AppPermissionState>((ref) {
  return PermissionController(ref.watch(permissionServiceProvider));
});

class PermissionController extends StateNotifier<AppPermissionState> {
  PermissionController(this._service) : super(AppPermissionState.unknown);

  final PermissionService _service;

  Future<void> requestAll() async {
    state = await _service.requestAllOnLaunch();
  }

  Future<void> refresh() async {
    state = await _service.currentPhotoPermission();
  }

  Future<bool> openSettings() => _service.openSystemSettings();
}

final albumTreeProvider = FutureProvider<List<AlbumNode>>((ref) async {
  final library = ref.watch(mediaLibraryProvider);
  return library.loadAlbumTree();
});

final pendingDeleteIdsProvider =
    StateNotifierProvider<PendingDeleteController, Set<String>>((ref) {
  return PendingDeleteController(ref.watch(pendingDeleteServiceProvider));
});

class PendingDeleteController extends StateNotifier<Set<String>> {
  PendingDeleteController(this._service) : super({}) {
    _load();
  }

  final PendingDeleteService _service;

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> mark(String id) async {
    state = await _service.mark(id);
  }

  Future<void> markMany(Iterable<String> ids) async {
    state = await _service.markMany(ids);
  }

  Future<void> unmark(String id) async {
    state = await _service.unmark(id);
  }

  Future<void> unmarkMany(Iterable<String> ids) async {
    state = await _service.unmarkMany(ids);
  }

  Future<void> clear() async {
    await _service.clear();
    state = {};
  }
}

final selectedAlbumProvider = StateProvider<AlbumNode?>((ref) => null);

final albumMediaProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, albumId) async {
  final library = ref.watch(mediaLibraryProvider);
  return library.loadMedia(albumId: albumId, recursive: true);
});

final exifProvider =
    FutureProvider.family<ExifInfo, MediaItem>((ref, item) async {
  return ref.watch(exifServiceProvider).loadFor(item);
});

class DuplicateScanState {
  const DuplicateScanState({
    this.scanning = false,
    this.progress = 0,
    this.groups = const [],
    this.error,
  });

  final bool scanning;
  final double progress;
  final List<DuplicateGroup> groups;
  final String? error;

  DuplicateScanState copyWith({
    bool? scanning,
    double? progress,
    List<DuplicateGroup>? groups,
    String? error,
  }) {
    return DuplicateScanState(
      scanning: scanning ?? this.scanning,
      progress: progress ?? this.progress,
      groups: groups ?? this.groups,
      error: error,
    );
  }
}

final duplicateScanProvider =
    StateNotifierProvider<DuplicateScanController, DuplicateScanState>((ref) {
  return DuplicateScanController(ref);
});

class DuplicateScanController extends StateNotifier<DuplicateScanState> {
  DuplicateScanController(this._ref) : super(const DuplicateScanState());

  final Ref _ref;

  Future<void> scanAlbum(String albumId) async {
    state = const DuplicateScanState(scanning: true);
    try {
      final media = await _ref.read(mediaLibraryProvider).loadMedia(
            albumId: albumId,
            recursive: true,
            filter: RequestFilter.images,
          );
      final groups = await _ref.read(duplicateServiceProvider).findGroups(
        media,
        onProgress: (p) {
          state = state.copyWith(progress: p, scanning: true);
        },
      );
      state = DuplicateScanState(groups: groups, progress: 1);
    } catch (e) {
      state = DuplicateScanState(error: e.toString());
    }
  }
}
