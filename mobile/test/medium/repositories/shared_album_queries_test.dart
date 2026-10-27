import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/data/db/main/table/remote/album_user.drift.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/map.model.dart';
import 'package:immich_mobile/infrastructure/repositories/shared_album_queries.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../repository_context.dart';

void main() {
  late MediumRepositoryContext ctx;
  late SharedAlbumQueries sut;

  setUpAll(initializeDateFormatting);
  setUp(() {
    ctx = MediumRepositoryContext();
    sut = SharedAlbumQueries(ctx.db);
  });
  tearDown(() => ctx.dispose());

  Future<void> share(String albumId, String userId) => ctx.db
      .into(ctx.db.remoteAlbumUserEntity)
      .insert(
        RemoteAlbumUserEntityCompanion(
          albumId: Value(albumId),
          userId: Value(userId),
          role: const Value(AlbumUserRole.viewer),
        ),
      );

  test('counts and pages share deduplication; private assets do not leak', () async {
    final me = await ctx.newUser();
    final other = await ctx.newUser();
    final album = await ctx.newRemoteAlbum(ownerId: other.id);
    final secondAlbum = await ctx.newRemoteAlbum(ownerId: other.id);
    await share(album.id, me.id);
    await share(secondAlbum.id, me.id);
    final own = await ctx.newRemoteAsset(ownerId: me.id, checksum: 'same', createdAt: DateTime.utc(2026, 1, 1));
    final copy = await ctx.newRemoteAsset(ownerId: other.id, checksum: 'same');
    final shared = await ctx.newRemoteAsset(ownerId: other.id, createdAt: DateTime.utc(2026, 1, 2));
    final private = await ctx.newRemoteAsset(ownerId: other.id);
    for (final id in [copy.id, shared.id]) {
      await ctx.newRemoteAlbumAsset(albumId: album.id, assetId: id);
      await ctx.newRemoteAlbumAsset(albumId: secondAlbum.id, assetId: id);
    }
    final query = sut.main([me.id], me.id, [album.id, secondAlbum.id], .day);
    final buckets = await query.bucketSource().first;
    expect(buckets.fold(0, (n, b) => n + b.assetCount), 2);
    final first = await query.assetSource(0, 1);
    final next = await query.assetSource(1, 1);
    expect([...first, ...next].map((a) => a.id), [shared.id, own.id]);
    expect([...first, ...next].map((a) => a.id), isNot(contains(private.id)));
  });

  test('synchronized membership removal hides foreign photos even when assets remain cached', () async {
    final me = await ctx.newUser();
    final other = await ctx.newUser();
    final album = await ctx.newRemoteAlbum(ownerId: other.id);
    await share(album.id, me.id);
    final asset = await ctx.newRemoteAsset(ownerId: other.id);
    await ctx.newRemoteAlbumAsset(albumId: album.id, assetId: asset.id);
    final query = sut.main([me.id], me.id, [album.id], .day);
    expect(await query.assetSource(0, 10), hasLength(1));
    await (ctx.db.remoteAlbumUserEntity.delete()
          ..where((row) => row.albumId.equals(album.id) & row.userId.equals(me.id)))
        .go();
    expect(await query.assetSource(0, 10), isEmpty);
    expect(await query.bucketSource().first, isEmpty);
    expect(await sut.watchAlbums(me.id).first, isEmpty);
  });

  test('local copies do not multiply a shared remote asset', () async {
    final me = await ctx.newUser();
    final other = await ctx.newUser();
    final album = await ctx.newRemoteAlbum(ownerId: other.id);
    await share(album.id, me.id);
    final asset = await ctx.newRemoteAsset(ownerId: other.id, checksum: 'shared-checksum');
    await ctx.newRemoteAlbumAsset(albumId: album.id, assetId: asset.id);
    await ctx.newLocalAsset(checksum: 'shared-checksum');
    await ctx.newLocalAsset(checksum: 'shared-checksum');
    final query = sut.main([me.id], me.id, [album.id], .day);
    final assets = await query.assetSource(0, 10);
    expect(assets, hasLength(1));
    expect(assets.single.id, asset.id);
    expect(assets.single.localId, isNotNull);
  });

  test('album-only photos remain visible without private stack metadata', () async {
    final me = await ctx.newUser();
    final other = await ctx.newUser();
    final album = await ctx.newRemoteAlbum(ownerId: other.id);
    await share(album.id, me.id);
    final asset = await ctx.newRemoteAsset(ownerId: other.id, stackId: 'private-stack');
    await ctx.newRemoteAlbumAsset(albumId: album.id, assetId: asset.id);
    final query = sut.main([me.id], me.id, [album.id], .day);
    final photo = (await query.assetSource(0, 10)).single as RemoteAsset;
    expect(photo.id, asset.id);
    expect(photo.stackId, isNull);
    expect((await query.bucketSource().first).single.assetCount, 1);
  });

  test('map filters before ranking and marker IDs agree with the timeline', () async {
    final me = await ctx.newUser();
    final other = await ctx.newUser();
    final album = await ctx.newRemoteAlbum(ownerId: other.id);
    await share(album.id, me.id);
    // Own copy has no GPS; it must not displace the shared copy with GPS.
    await ctx.newRemoteAsset(ownerId: me.id, checksum: 'same');
    final asset = await ctx.newRemoteAsset(ownerId: other.id, checksum: 'same');
    await ctx.newRemoteAlbumAsset(albumId: album.id, assetId: asset.id);
    await ctx.db.customStatement('INSERT INTO remote_exif_entity(asset_id, latitude, longitude) VALUES (?, ?, ?)', [
      asset.id,
      48.3,
      10.9,
    ]);
    final options = TimelineMapOptions(
      bounds: LatLngBounds(southwest: const LatLng(48, 10), northeast: const LatLng(49, 11)),
      sharedAlbumIds: [album.id],
      sharedAlbumUserId: me.id,
    );
    final query = sut.map([me.id], options, .month);
    final markers = await sut.markers([me.id], options, options.bounds);
    final assets = await query.assetSource(0, 10);
    expect(markers.map((m) => m.assetId), [asset.id]);
    expect(assets.map((a) => a.id), [asset.id]);
    expect((await query.bucketSource().first).single.assetCount, 1);
  });
}
