/// SQL shared by the extra timeline and map queries. All user values are bound.
/// Filtering precedes checksum ranking, counting and pagination.
class SharedAlbumSql {
  final String sql;
  final List<Object> arguments;

  const SharedAlbumSql(this.sql, this.arguments);

  static const accessibleAlbums = '''
SELECT album.id, album.name
FROM remote_album_entity album
WHERE EXISTS (
  SELECT 1 FROM remote_album_user_entity mine
  WHERE mine.album_id = album.id AND mine.user_id = ?
) AND EXISTS (
  SELECT 1 FROM remote_album_user_entity other
  WHERE other.album_id = album.id AND other.user_id <> ?
)
ORDER BY album.name COLLATE NOCASE, album.id
''';

  factory SharedAlbumSql.candidates({
    required List<String> ownerIds,
    required List<String> albumIds,
    required String currentUserId,
    bool map = false,
    bool includeArchived = false,
    bool onlyFavorites = false,
    double south = -90,
    double north = 90,
    double west = -180,
    double east = 180,
    DateTime? from,
    DateTime? to,
  }) {
    final arguments = <Object>[];
    String bind(Object value) {
      arguments.add(value);
      return '?';
    }

    String inList(List<String> values) => values.isEmpty ? '(NULL)' : '(${values.map(bind).join(',')})';

    final owners = inList(ownerIds);
    final albums = inList(albumIds);
    final mine = bind(currentUserId);
    final other = bind(currentUserId);
    final filters = <String>[
      'a.deleted_at IS NULL',
      'a.visibility IN (${map && includeArchived ? '0,2' : '0'})',
      '''(a.owner_id IN $owners OR EXISTS (
        SELECT 1 FROM remote_album_asset_entity membership
        JOIN remote_album_entity album ON album.id = membership.album_id
        WHERE membership.asset_id = a.id AND membership.album_id IN $albums
        AND EXISTS (SELECT 1 FROM remote_album_user_entity u
          WHERE u.album_id = album.id AND u.user_id = $mine)
        AND EXISTS (SELECT 1 FROM remote_album_user_entity u
          WHERE u.album_id = album.id AND u.user_id <> $other)
      ))''',
    ];
    if (map) {
      filters.add('e.latitude BETWEEN ${bind(south)} AND ${bind(north)}');
      if (west <= east) {
        filters.add('e.longitude BETWEEN ${bind(west)} AND ${bind(east)}');
      } else {
        filters.add('(e.longitude >= ${bind(west)} OR e.longitude <= ${bind(east)})');
      }
      if (onlyFavorites) {
        filters.add('a.is_favorite = 1');
      }
      if (from != null) {
        filters.add('julianday(a.created_at) >= julianday(${bind(from.toUtc().toIso8601String())})');
      }
      if (to != null) {
        filters.add('julianday(a.created_at) <= julianday(${bind(to.toUtc().toIso8601String())})');
      }
    } else {
      // Album-only sharing does not synchronize the owner's private stacks.
      // Treat these shared photos individually, as the album view does. Keep
      // the stock primary-only rule for the existing owner/partner timeline.
      final albumOnlyOwner = ownerIds.isEmpty ? '1' : 'a.owner_id NOT IN ${inList(ownerIds)}';
      filters.add('''($albumOnlyOwner OR a.stack_id IS NULL OR EXISTS (
        SELECT 1 FROM stack_entity stack WHERE stack.id = a.stack_id AND stack.primary_asset_id = a.id
      ))''');
    }
    final preferredOwner = bind(currentUserId);
    return SharedAlbumSql('''
WITH eligible AS (
  SELECT a.*${map ? ', e.latitude, e.longitude' : ''}
  FROM remote_asset_entity a
  ${map ? 'JOIN remote_exif_entity e ON e.asset_id = a.id' : ''}
  WHERE ${filters.join(' AND ')}
), ranked AS (
  SELECT eligible.*, ROW_NUMBER() OVER (
    PARTITION BY checksum, CASE WHEN checksum = '' THEN id ELSE '' END
    ORDER BY (owner_id = $preferredOwner) DESC, id
  ) AS checksum_rank FROM eligible
), visible_remote AS (
  SELECT * FROM ranked WHERE checksum_rank = 1
)
''', arguments);
  }

  SharedAlbumSql mainRows(List<String> ownerIds) {
    final owners = ownerIds.isEmpty ? '(NULL)' : '(${List.filled(ownerIds.length, '?').join(',')})';
    return SharedAlbumSql(
      '''$sql, visible AS (
  SELECT a.id AS remote_id,
    (SELECT l.id FROM local_asset_entity l WHERE l.checksum = a.checksum ORDER BY l.id LIMIT 1) AS local_id,
    a.created_at, a.local_date_time
  FROM visible_remote a
  UNION ALL
  SELECT NULL AS remote_id, l.id AS local_id, l.created_at, NULL AS local_date_time
  FROM local_asset_entity l
  WHERE NOT EXISTS (SELECT 1 FROM remote_asset_entity a
    WHERE a.checksum = l.checksum AND a.owner_id IN $owners)
  AND NOT EXISTS (SELECT 1 FROM visible_remote a WHERE a.checksum = l.checksum)
  AND EXISTS (SELECT 1 FROM local_album_asset_entity laa
    JOIN local_album_entity la ON la.id = laa.album_id
    WHERE laa.asset_id = l.id AND la.backup_selection = 0)
  AND NOT EXISTS (SELECT 1 FROM local_album_asset_entity laa
    JOIN local_album_entity la ON la.id = laa.album_id
    WHERE laa.asset_id = l.id AND la.backup_selection = 2)
)
''',
      [...arguments, ...ownerIds],
    );
  }
}
