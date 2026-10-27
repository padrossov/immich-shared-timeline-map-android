import 'package:drift/drift.dart';
import 'package:immich_mobile/data/db/main/database.dart';
import 'package:immich_mobile/data/db/main/table/local/asset.dart';
import 'package:immich_mobile/data/db/main/table/remote/asset.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/map.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/infrastructure/repositories/shared_album_sql.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Extra queries are used only while at least one shared album is selected.
/// The stock queries remain the fallback when the selection is empty.
class SharedAlbumQueries {
  final Drift db;
  const SharedAlbumQueries(this.db);

  Selectable<QueryRow> _select(SharedAlbumSql query, String suffix, [List<Object> arguments = const []]) =>
      db.customSelect(
        '${query.sql} $suffix',
        variables: [...query.arguments, ...arguments]
            .map(
              (value) => switch (value) {
                final String v => Variable<String>(v),
                final int v => Variable<int>(v),
                final double v => Variable<double>(v),
                _ => throw ArgumentError.value(value, 'SQL parameter'),
              },
            )
            .toList(),
        readsFrom: {
          db.remoteAssetEntity,
          db.remoteExifEntity,
          db.remoteAlbumEntity,
          db.remoteAlbumAssetEntity,
          db.remoteAlbumUserEntity,
          db.stackEntity,
          db.localAssetEntity,
          db.localAlbumEntity,
          db.localAlbumAssetEntity,
        },
      );

  Stream<List<({String id, String name})>> watchAlbums(String userId) => db
      .customSelect(
        SharedAlbumSql.accessibleAlbums,
        variables: [Variable(userId), Variable(userId)],
        readsFrom: {db.remoteAlbumEntity, db.remoteAlbumUserEntity},
      )
      .watch()
      .map((rows) => rows.map((row) => (id: row.read<String>('id'), name: row.read<String>('name'))).toList());

  TimelineQuery main(List<String> userIds, String userId, List<String> albumIds, GroupAssetsBy groupBy) {
    final query = SharedAlbumSql.candidates(
      ownerIds: userIds,
      albumIds: albumIds,
      currentUserId: userId,
    ).mainRows(userIds);
    return (
      origin: TimelineOrigin.main,
      bucketSource: () => _buckets(query, 'visible', groupBy),
      assetSource: (offset, count) => _assets(query, 'visible', offset, count, groupBy, userIds),
    );
  }

  SharedAlbumSql _map(List<String> userIds, TimelineMapOptions options, {LatLngBounds? bounds}) {
    final area = bounds ?? options.bounds;
    final range = options.timeRange;
    final hasRange = range.from != null || range.to != null;
    return SharedAlbumSql.candidates(
      ownerIds: userIds,
      albumIds: options.sharedAlbumIds,
      currentUserId: options.sharedAlbumUserId,
      map: true,
      includeArchived: options.includeArchived,
      onlyFavorites: options.onlyFavorites,
      south: area.southwest.latitude,
      north: area.northeast.latitude,
      west: area.southwest.longitude,
      east: area.northeast.longitude,
      from: hasRange
          ? range.from
          : options.relativeDays > 0
          ? DateTime.now().toUtc().subtract(Duration(days: options.relativeDays))
          : null,
      to: hasRange ? range.to : null,
    );
  }

  TimelineQuery map(List<String> userIds, TimelineMapOptions options, GroupAssetsBy groupBy) {
    final query = _map(userIds, options);
    return (
      origin: TimelineOrigin.map,
      bucketSource: () => _buckets(query, 'visible_remote', groupBy),
      assetSource: (offset, count) => _assets(query, 'visible_remote', offset, count, groupBy, userIds),
    );
  }

  Future<List<Marker>> markers(List<String> userIds, TimelineMapOptions options, LatLngBounds? bounds) async {
    final query = _map(
      userIds,
      options,
      bounds: bounds ?? LatLngBounds(southwest: const LatLng(-90, -180), northeast: const LatLng(90, 180)),
    );
    final rows = await _select(
      query,
      'SELECT id, latitude, longitude FROM visible_remote ORDER BY id LIMIT 10000',
    ).get();
    return rows
        .map(
          (row) => Marker(
            assetId: row.read<String>('id'),
            location: LatLng(row.read<double>('latitude'), row.read<double>('longitude')),
          ),
        )
        .toList();
  }

  String _date(GroupAssetsBy groupBy) {
    final format = groupBy == GroupAssetsBy.month ? '%Y-%m' : '%Y-%m-%d';
    return "COALESCE(strftime('$format', local_date_time), strftime('$format', created_at, 'localtime'))";
  }

  Stream<List<Bucket>> _buckets(SharedAlbumSql query, String table, GroupAssetsBy groupBy) {
    if (groupBy == GroupAssetsBy.none) {
      return _select(query, 'SELECT count(*) AS asset_count FROM $table').watch().map((rows) {
        final count = rows.single.read<int>('asset_count');
        return count == 0 ? <Bucket>[] : [Bucket(assetCount: count)];
      });
    }
    return _select(query, '''SELECT ${_date(groupBy)} AS bucket_date, count(*) AS asset_count
      FROM $table GROUP BY bucket_date ORDER BY bucket_date DESC''').watch().map(
      (rows) => rows
          .map(
            (row) => TimeBucket(
              date: DateFormat(
                groupBy == GroupAssetsBy.month ? 'y-M' : 'y-M-d',
                'en',
              ).parse(row.read<String>('bucket_date')),
              assetCount: row.read<int>('asset_count'),
            ),
          )
          .toList(),
    );
  }

  Future<List<BaseAsset>> _assets(
    SharedAlbumSql query,
    String table,
    int offset,
    int count,
    GroupAssetsBy groupBy,
    List<String> stackOwnerIds,
  ) async {
    // Resolve IDs and their DTOs in one snapshot so a concurrent sync cannot
    // remove an entity between the page query and the DTO lookup.
    return db.transaction(() async {
      final main = table == 'visible';
      final columns = main ? 'remote_id, local_id' : 'id AS remote_id, NULL AS local_id';
      final stableId = main ? 'COALESCE(remote_id, local_id)' : 'id';
      final order = groupBy == GroupAssetsBy.none ? '' : '${_date(groupBy)} DESC,';
      final rows = await _select(
        query,
        'SELECT $columns FROM $table ORDER BY $order created_at DESC, $stableId LIMIT ? OFFSET ?',
        [count, offset],
      ).get();
      final remoteIds = rows.map((row) => row.readNullable<String>('remote_id')).nonNulls.toList();
      final localIds = rows.map((row) => row.readNullable<String>('local_id')).nonNulls.toList();
      final remote = await (db.remoteAssetEntity.select()..where((a) => a.id.isIn(remoteIds))).get();
      final local = await (db.localAssetEntity.select()..where((a) => a.id.isIn(localIds))).get();
      final remoteById = {for (final asset in remote) asset.id: asset};
      final localById = {for (final asset in local) asset.id: asset};
      return rows.map((row) {
        final remoteId = row.readNullable<String>('remote_id');
        final localId = row.readNullable<String>('local_id');
        if (remoteId == null) {
          return localById[localId]!.toDto();
        }
        final asset = remoteById[remoteId]!;
        return asset.toDto(localId: localId, includeStack: stackOwnerIds.contains(asset.ownerId));
      }).toList();
    });
  }
}
