import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipic/services/demo_library_service.dart';
import 'package:swipic/services/duplicate_service.dart';
import 'package:swipic/services/media_library_service.dart';
import 'package:swipic/services/pending_delete_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoLibraryService', () {
    test('exposes nested travel > tokyo album', () async {
      final library = DemoLibraryService();
      final tree = await library.loadAlbumTree();
      final travel = tree.firstWhere((a) => a.id == 'album_travel');
      expect(travel.hasChildren, isTrue);
      expect(travel.children.any((c) => c.id == 'album_tokyo'), isTrue);

      final tokyo = await library.loadMedia(albumId: 'album_tokyo');
      expect(tokyo, isNotEmpty);
      expect(tokyo.every((m) => m.albumId == 'album_tokyo'), isTrue);

      final recursive = await library.loadMedia(
        albumId: 'album_travel',
        recursive: true,
      );
      expect(recursive.length, greaterThan(tokyo.length));
    });

    test('includes live photos and videos', () async {
      final library = DemoLibraryService();
      final all = await library.loadAllMedia();
      expect(all.any((m) => m.isLivePhoto), isTrue);
      expect(all.any((m) => m.isVideo), isTrue);
    });
  });

  group('DuplicateService offline scan', () {
    test('finds exact duplicate in demo library', () async {
      final library = DemoLibraryService();
      final media = await library.loadAllMedia();
      final service = DuplicateService(library);
      final groups = await service.findGroups(media);
      expect(groups, isNotEmpty);
      expect(groups.any((g) => g.items.any((i) => i.id == 'camera_1')), isTrue);
      expect(
        groups.any((g) => g.items.any((i) => i.id == 'camera_1_dup')),
        isTrue,
      );
    });
  });

  group('PendingDeleteService', () {
    test('marks and unmarks ids locally', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PendingDeleteService();
      await service.mark('a');
      await service.mark('b');
      expect(await service.load(), {'a', 'b'});
      await service.unmark('a');
      expect(await service.load(), {'b'});
      await service.clear();
      expect(await service.load(), isEmpty);
    });
  });
}
