import 'package:flutter_test/flutter_test.dart';
import 'package:swipic/models/album_node.dart';
import 'package:swipic/models/duplicate_group.dart';
import 'package:swipic/models/media_item.dart';

MediaItem item({
  required String id,
  required int bytes,
  required int w,
  required int h,
  String albumId = 'a',
  DateTime? date,
}) {
  return MediaItem(
    id: id,
    albumId: albumId,
    albumName: albumId,
    kind: MediaKind.image,
    createDate: date ?? DateTime(2024, 1, 1),
    width: w,
    height: h,
    byteSize: bytes,
  );
}

void main() {
  group('DuplicateGroup keep strategies', () {
    final group = DuplicateGroup(
      id: 'g1',
      kind: DuplicateKind.exact,
      items: [
        item(id: 'small', bytes: 1000, w: 1000, h: 1000, albumId: 'screenshots'),
        item(
          id: 'large',
          bytes: 5000,
          w: 4000,
          h: 3000,
          albumId: 'camera',
          date: DateTime(2025, 1, 1),
        ),
        item(
          id: 'mid',
          bytes: 2500,
          w: 2000,
          h: 2000,
          albumId: 'travel',
          date: DateTime(2023, 1, 1),
        ),
      ],
    );

    test('largest keeps biggest file', () {
      expect(group.suggestKeep(KeepStrategy.largest)?.id, 'large');
    });

    test('smallest keeps smallest file', () {
      expect(group.suggestKeep(KeepStrategy.smallest)?.id, 'small');
    });

    test('newest / oldest', () {
      expect(group.suggestKeep(KeepStrategy.newest)?.id, 'large');
      expect(group.suggestKeep(KeepStrategy.oldest)?.id, 'mid');
    });

    test('inAlbum prefers selected album', () {
      expect(
        group.suggestKeep(KeepStrategy.inAlbum, preferredAlbumId: 'travel')?.id,
        'mid',
      );
    });

    test('idsToDelete excludes keep', () {
      final delete = group.idsToDelete(KeepStrategy.largest);
      expect(delete, {'small', 'mid'});
    });

    test('potentialSaveBytes excludes one keep candidate', () {
      expect(group.potentialSaveBytes, 1000 + 2500);
    });
  });

  group('AlbumNode nesting', () {
    test('collectIds includes nested albums', () {
      const travel = AlbumNode(
        id: 'travel',
        name: '旅行',
        assetCount: 10,
        children: [
          AlbumNode(
            id: 'tokyo',
            name: '东京',
            assetCount: 4,
            parentId: 'travel',
            depth: 1,
          ),
          AlbumNode(
            id: 'osaka',
            name: '大阪',
            assetCount: 3,
            parentId: 'travel',
            depth: 1,
          ),
        ],
      );
      expect(travel.collectIds(), {'travel', 'tokyo', 'osaka'});
      expect(travel.flatten().map((e) => e.id).toList(),
          ['travel', 'tokyo', 'osaka']);
    });
  });
}
