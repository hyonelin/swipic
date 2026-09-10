import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import 'app_providers.dart';

enum SwipeDecision { keep, delete }

class CleanupSession {
  const CleanupSession({
    required this.albumId,
    required this.albumName,
    required this.items,
    this.index = 0,
    this.kept = const {},
    this.history = const [],
  });

  final String albumId;
  final String albumName;
  final List<MediaItem> items;
  final int index;
  final Set<String> kept;
  final List<SwipeDecision> history;

  MediaItem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  bool get isFinished => index >= items.length;

  int get remaining => (items.length - index).clamp(0, items.length);

  CleanupSession copyWith({
    int? index,
    Set<String>? kept,
    List<SwipeDecision>? history,
    List<MediaItem>? items,
  }) {
    return CleanupSession(
      albumId: albumId,
      albumName: albumName,
      items: items ?? this.items,
      index: index ?? this.index,
      kept: kept ?? this.kept,
      history: history ?? this.history,
    );
  }
}

final cleanupSessionProvider =
    StateNotifierProvider<CleanupController, CleanupSession?>((ref) {
  return CleanupController(ref);
});

class CleanupController extends StateNotifier<CleanupSession?> {
  CleanupController(this._ref) : super(null);

  final Ref _ref;

  Future<void> start({
    required String albumId,
    required String albumName,
    bool skipPending = true,
  }) async {
    var items = await _ref.read(mediaLibraryProvider).loadMedia(
          albumId: albumId,
          recursive: true,
        );
    if (skipPending) {
      final pending = _ref.read(pendingDeleteIdsProvider);
      items = items.where((e) => !pending.contains(e.id)).toList();
    }
    state = CleanupSession(
      albumId: albumId,
      albumName: albumName,
      items: items,
    );
  }

  Future<void> decide(SwipeDecision decision) async {
    final session = state;
    if (session == null || session.current == null) return;
    final current = session.current!;

    if (decision == SwipeDecision.delete) {
      await _ref.read(pendingDeleteIdsProvider.notifier).mark(current.id);
    }

    final kept = {...session.kept};
    if (decision == SwipeDecision.keep) kept.add(current.id);

    state = session.copyWith(
      index: session.index + 1,
      kept: kept,
      history: [...session.history, decision],
    );
  }

  Future<void> undo() async {
    final session = state;
    if (session == null || session.history.isEmpty) return;
    final last = session.history.last;
    final prevIndex = session.index - 1;
    if (prevIndex < 0) return;
    final item = session.items[prevIndex];

    if (last == SwipeDecision.delete) {
      await _ref.read(pendingDeleteIdsProvider.notifier).unmark(item.id);
    }

    final kept = {...session.kept}..remove(item.id);
    final history = [...session.history]..removeLast();
    state = session.copyWith(index: prevIndex, kept: kept, history: history);
  }

  void reset() => state = null;
}
