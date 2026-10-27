import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/map.model.dart';
import 'package:immich_mobile/domain/models/shared_album_preferences.dart';
import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/infrastructure/repositories/shared_album_queries.dart';
import 'package:immich_mobile/presentation/widgets/map/map.state.dart';
import 'package:immich_mobile/providers/infrastructure/db.provider.dart';
import 'package:immich_mobile/providers/infrastructure/store.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/utils/async_mutex.dart';

enum SharedAlbumView { photos, map }

final _serverProvider = StreamProvider<String?>((ref) => ref.watch(storeServiceProvider).watch(StoreKey.serverUrl));

final _accountProvider = Provider<String>((ref) {
  final server =
      ref.watch(_serverProvider).valueOrNull ?? ref.watch(storeServiceProvider).tryGet(StoreKey.serverUrl) ?? '';
  final user = ref.watch(currentUserProvider)?.id ?? '';
  return SharedAlbumPreferences.key(server, user, '');
});

final _writeMutexProvider = Provider((_) => AsyncMutex());

class SharedAlbumSelection extends FamilyNotifier<Set<String>, SharedAlbumView> {
  int _generation = 0;

  @override
  Set<String> build(SharedAlbumView arg) {
    _generation++;
    ref.onDispose(() => _generation++);
    final account = ref.watch(_accountProvider);
    final store = ref.watch(storeServiceProvider);
    return SharedAlbumPreferences.read(store.tryGet(StoreKey.sharedAlbumSelections), '$account:${arg.name}');
  }

  Future<void> save(Set<String> ids) async {
    final generation = _generation;
    final account = ref.read(_accountProvider);
    final store = ref.read(storeServiceProvider);
    final mutex = ref.read(_writeMutexProvider);
    final key = '$account:${arg.name}';
    // Serialize read-modify-write across the two independent views.
    await mutex.run(() async {
      final value = SharedAlbumPreferences.write(store.tryGet(StoreKey.sharedAlbumSelections), key, ids);
      await store.put(StoreKey.sharedAlbumSelections, value);
    });
    if (_generation == generation) {
      state = Set.unmodifiable(ids);
    }
  }
}

final sharedAlbumSelectionProvider = NotifierProvider.family<SharedAlbumSelection, Set<String>, SharedAlbumView>(
  SharedAlbumSelection.new,
);

final sharedAlbumCatalogProvider = StreamProvider<List<({String id, String name})>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return Stream.value([]);
  }
  return SharedAlbumQueries(ref.watch(driftProvider)).watchAlbums(userId);
});

final sharedAlbumMapOptionsProvider = Provider<TimelineMapOptions>((ref) {
  final ids = ref.watch(sharedAlbumSelectionProvider(SharedAlbumView.map));
  return ref
      .watch(mapStateProvider.select((state) => state.toOptions()))
      .copyWith(sharedAlbumIds: ids.toList()..sort(), sharedAlbumUserId: ref.watch(currentUserProvider)?.id ?? '');
});

// A synchronized album/asset/EXIF update can change markers without changing
// the saved filter. Invalidate the cached marker query in that case as well.
final sharedAlbumMapRevisionProvider = StreamProvider<int>((ref) {
  if (ref.watch(sharedAlbumSelectionProvider(SharedAlbumView.map)).isEmpty) {
    return const Stream.empty();
  }
  final db = ref.watch(driftProvider);
  var revision = 0;
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.remoteAssetEntity,
          db.remoteExifEntity,
          db.remoteAlbumEntity,
          db.remoteAlbumAssetEntity,
          db.remoteAlbumUserEntity,
        },
      )
      .watch()
      .map((_) => ++revision);
});
