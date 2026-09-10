import 'package:shared_preferences/shared_preferences.dart';

/// Soft-delete queue: swipe-to-delete only marks items; user confirms later.
class PendingDeleteService {
  static const _key = 'swipic_pending_delete_ids';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList()..sort());
  }

  Future<Set<String>> mark(String id) async {
    final ids = await load();
    ids.add(id);
    await save(ids);
    return ids;
  }

  Future<Set<String>> markMany(Iterable<String> more) async {
    final ids = await load();
    ids.addAll(more);
    await save(ids);
    return ids;
  }

  Future<Set<String>> unmark(String id) async {
    final ids = await load();
    ids.remove(id);
    await save(ids);
    return ids;
  }

  Future<Set<String>> unmarkMany(Iterable<String> remove) async {
    final ids = await load();
    ids.removeAll(remove);
    await save(ids);
    return ids;
  }

  Future<void> clear() async {
    await save({});
  }
}
