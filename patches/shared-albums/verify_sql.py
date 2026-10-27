#!/usr/bin/env python3
"""Exercise the actual Dart SQL builder with SQLite, without a Flutter engine."""
import argparse
import json
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path, help='Patched Immich source checkout')
parser.add_argument('--dart', default='dart')
args = parser.parse_args()
source = args.source.resolve()
sql_uri = (source / 'mobile/lib/infrastructure/repositories/shared_album_sql.dart').as_uri()
prefs_uri = (source / 'mobile/lib/domain/models/shared_album_preferences.dart').as_uri()
bridge = """import 'dart:convert';
import 'SQL_URI';
import 'PREFS_URI';
void main() {
  final queries = <String, Object>{};
  void add(String name, SharedAlbumSql query) {
    queries[name] = {'sql': query.sql, 'args': query.arguments};
  }
  SharedAlbumSql make({bool map = false, bool archived = false, bool favorites = false,
      double west = -180, double east = 180, DateTime? from, DateTime? to,
      List<String> owners = const ['me'], List<String> albums = const ['album', 'second']}) =>
    SharedAlbumSql.candidates(ownerIds: owners, albumIds: albums, currentUserId: 'me',
      map: map, includeArchived: archived, onlyFavorites: favorites,
      west: west, east: east, from: from, to: to);
  add('main', make().mainRows(['me']));
  add('remote', make());
  add('map', make(map: true));
  add('archive', make(map: true, archived: true));
  add('favorite', make(map: true, favorites: true));
  add('dateline', make(map: true, west: 170, east: -170));
  add('range', make(map: true, from: DateTime.utc(2026, 1, 2), to: DateTime.utc(2026, 1, 3)));
  add('partner', make(owners: ['me', 'partner']));
  add('empty', make(owners: [], albums: []));
  final p = SharedAlbumPreferences.key('server', 'me', 'photos');
  final m = SharedAlbumPreferences.key('server', 'me', 'map');
  final other = SharedAlbumPreferences.key('other', 'me', 'photos');
  var value = SharedAlbumPreferences.write(null, p, {'album'});
  value = SharedAlbumPreferences.write(value, m, {'second'});
  if (!SharedAlbumPreferences.read(value, p).contains('album') ||
      !SharedAlbumPreferences.read(value, m).contains('second') ||
      SharedAlbumPreferences.read(value, other).isNotEmpty ||
      SharedAlbumPreferences.read('{broken', p).isNotEmpty) {
    throw StateError('Selection persistence regression');
  }
  queries['catalog'] = SharedAlbumSql.accessibleAlbums;
  print(jsonEncode(queries));
}
""".replace('SQL_URI', sql_uri).replace('PREFS_URI', prefs_uri)
with tempfile.TemporaryDirectory() as tmp:
    script = Path(tmp) / 'bridge.dart'
    script.write_text(bridge)
    result = subprocess.run([args.dart, str(script)], check=True, capture_output=True, text=True)
    queries = json.loads(result.stdout)

class SharedAlbumSqlTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.executescript('''
        CREATE TABLE remote_asset_entity(id TEXT PRIMARY KEY, checksum TEXT, owner_id TEXT,
          visibility INTEGER DEFAULT 0, deleted_at TEXT, created_at TEXT DEFAULT '2026-01-01T12:00:00Z',
          local_date_time TEXT, stack_id TEXT, is_favorite INTEGER DEFAULT 0);
        CREATE TABLE remote_album_entity(id TEXT PRIMARY KEY, name TEXT);
        CREATE TABLE remote_album_user_entity(album_id TEXT, user_id TEXT);
        CREATE TABLE remote_album_asset_entity(album_id TEXT, asset_id TEXT);
        CREATE TABLE remote_exif_entity(asset_id TEXT PRIMARY KEY, latitude REAL, longitude REAL);
        CREATE TABLE stack_entity(id TEXT PRIMARY KEY, primary_asset_id TEXT);
        CREATE TABLE local_asset_entity(id TEXT PRIMARY KEY, checksum TEXT, created_at TEXT);
        CREATE TABLE local_album_entity(id TEXT PRIMARY KEY, backup_selection INTEGER);
        CREATE TABLE local_album_asset_entity(asset_id TEXT, album_id TEXT);
        INSERT INTO remote_album_entity VALUES ('album','First'),('second','Second'),('private','Private');
        INSERT INTO remote_album_user_entity VALUES ('album','me'),('album','other'),
          ('second','me'),('second','other'),('private','other');
        ''')
    def tearDown(self):
        self.db.close()
    def asset(self, id, checksum=None, owner='other', shared=True, gps=True, **fields):
        fields = {'id': id, 'checksum': checksum or id, 'owner_id': owner, **fields}
        self.db.execute(f'INSERT INTO remote_asset_entity({",".join(fields)}) VALUES ({",".join("?" for _ in fields)})', list(fields.values()))
        if shared:
            self.db.execute('INSERT INTO remote_album_asset_entity VALUES (?,?)', ('album', id))
        if gps:
            self.db.execute('INSERT INTO remote_exif_entity VALUES (?,?,?)', (id,48.3,10.9))
    def rows(self, kind='remote', suffix='SELECT id FROM visible_remote', extra=()):
        q = queries[kind]
        return self.db.execute(q['sql'] + suffix, q['args'] + list(extra)).fetchall()
    def test_multi_album_and_checksum_prefer_own(self):
        self.asset('own', 'same', owner='me', shared=False)
        self.asset('copy', 'same')
        self.asset('unique')
        self.db.execute("INSERT INTO remote_album_asset_entity VALUES ('second','unique')")
        self.assertEqual(self.rows(suffix='SELECT id FROM visible_remote ORDER BY id'), [('own',),('unique',)])
    def test_foreign_representative_is_stable(self):
        self.asset('z', 'same'); self.asset('a', 'same')
        self.assertEqual(self.rows(), [('a',)])
    def test_private_photos_do_not_leak(self):
        self.asset('selected'); self.asset('private', shared=False)
        self.assertEqual(self.rows(), [('selected',)])
    def test_revocation_with_cached_assets(self):
        self.asset('selected')
        self.db.execute("DELETE FROM remote_album_user_entity WHERE album_id='album' AND user_id='me'")
        self.assertEqual(self.rows(), [])
    def test_album_asset_removed(self):
        self.asset('selected')
        self.db.execute('DELETE FROM remote_album_asset_entity')
        self.assertEqual(self.rows(), [])
    def test_deleted_album_even_with_stale_junction(self):
        self.asset('selected')
        self.db.execute("DELETE FROM remote_album_entity WHERE id='album'")
        self.assertEqual(self.rows(), [])
    def test_map_filters_before_checksum_ranking(self):
        self.asset('own', 'same', owner='me', gps=False)
        self.asset('shared', 'same')
        self.assertEqual(self.rows('map'), [('shared',)])
    def test_hidden_and_locked_never_in_archive_map(self):
        self.asset('hidden', visibility=1); self.asset('archive', visibility=2); self.asset('locked', visibility=3)
        self.assertEqual(self.rows('map'), [])
        self.assertEqual(self.rows('archive'), [('archive',)])
    def test_trash_does_not_displace_visible_copy(self):
        self.asset('own', 'same', owner='me', deleted_at='2026-01-01')
        self.asset('shared', 'same')
        self.assertEqual(self.rows(), [('shared',)])
    def test_favorite_filter_before_ranking(self):
        self.asset('own', 'same', owner='me'); self.asset('shared', 'same', is_favorite=1)
        self.assertEqual(self.rows('favorite'), [('shared',)])
    def test_date_range(self):
        self.asset('old', created_at='2026-01-01T00:00:00Z')
        self.asset('inside', created_at='2026-01-02T00:00:00Z')
        self.asset('later', created_at='2026-01-04T00:00:00Z')
        self.assertEqual(self.rows('range'), [('inside',)])
    def test_antimeridian(self):
        for id, longitude in [('east',175),('west',-175),('outside',0)]:
            self.asset(id)
            self.db.execute('UPDATE remote_exif_entity SET longitude=? WHERE asset_id=?',(longitude,id))
        self.assertEqual(set(self.rows('dateline')), {('east',),('west',)})
    def test_stack_primary(self):
        self.asset('primary', owner='me', stack_id='stack'); self.asset('child', owner='me', stack_id='stack')
        self.db.execute("INSERT INTO stack_entity VALUES ('stack','primary')")
        self.assertEqual(self.rows(), [('primary',)])
    def test_album_only_stacks_do_not_hide_shared_photos_or_leak_private_primary(self):
        self.asset('unknown-stack-child', stack_id='unknown')
        self.asset('known-stack-child', stack_id='known')
        self.asset('private-primary', stack_id='known', shared=False)
        self.db.execute("INSERT INTO stack_entity VALUES ('known','private-primary')")
        self.assertEqual(set(self.rows()), {('unknown-stack-child',),('known-stack-child',)})
    def test_local_merge_and_exclusion(self):
        self.asset('shared', 'same')
        self.db.executescript("""INSERT INTO local_asset_entity VALUES ('local1','same','2026-01-01'),
          ('local2','same','2026-01-01'),('only-local','different','2026-01-01'),('excluded','excluded','2026-01-01');
          INSERT INTO local_album_entity VALUES ('selected',0),('excluded',2);
          INSERT INTO local_album_asset_entity VALUES ('local1','selected'),('local2','selected'),
          ('only-local','selected'),('excluded','selected'),('excluded','excluded');""")
        self.assertEqual(self.rows('main','SELECT remote_id,local_id FROM visible ORDER BY local_id'),
          [('shared','local1'),(None,'only-local')])
    def test_pagination_and_count_agree(self):
        for n in range(25):
            self.asset(f'asset{n:02}', checksum=f'checksum{n//2}')
        total = self.rows(suffix='SELECT COUNT(*) FROM visible_remote')[0][0]
        pages = []
        for offset in range(0,total,3):
            pages += self.rows(suffix='SELECT id FROM visible_remote ORDER BY id LIMIT ? OFFSET ?',extra=(3,offset))
        self.assertEqual(len(pages),13)
        self.assertEqual(len(set(pages)),total)
    def test_partner_and_empty_lists(self):
        self.asset('partner-asset', owner='partner', shared=False)
        self.assertEqual(self.rows('partner'), [('partner-asset',)])
        self.assertEqual(self.rows('empty'), [])
    def test_catalog_requires_membership_and_another_user(self):
        self.assertEqual(self.db.execute(queries['catalog'],['me','me']).fetchall(), [('album','First'),('second','Second')])
        self.db.execute("DELETE FROM remote_album_user_entity WHERE user_id='other'")
        self.assertEqual(self.db.execute(queries['catalog'],['me','me']).fetchall(), [])

unittest.main(argv=['verify_sql'], verbosity=2)
