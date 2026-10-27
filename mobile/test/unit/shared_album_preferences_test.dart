import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/shared_album_preferences.dart';

void main() {
  test('selections survive serialization and stay separate by server, user and view', () {
    final photos = SharedAlbumPreferences.key('server-a', 'user-a', 'photos');
    final map = SharedAlbumPreferences.key('server-a', 'user-a', 'map');
    var value = SharedAlbumPreferences.write(null, photos, {'album-a'});
    value = SharedAlbumPreferences.write(value, map, {'album-b'});
    expect(SharedAlbumPreferences.read(value, photos), {'album-a'});
    expect(SharedAlbumPreferences.read(value, map), {'album-b'});
    expect(SharedAlbumPreferences.read(value, SharedAlbumPreferences.key('server-b', 'user-a', 'photos')), isEmpty);
    expect(SharedAlbumPreferences.read(value, SharedAlbumPreferences.key('server-a', 'user-b', 'photos')), isEmpty);
  });

  test('missing or malformed storage falls back to no added albums', () {
    for (final value in [null, '{broken', '[]', '{"key":3}']) {
      expect(SharedAlbumPreferences.read(value, 'key'), isEmpty);
    }
  });
}
