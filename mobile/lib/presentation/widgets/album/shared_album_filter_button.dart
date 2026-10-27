import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/shared_album_filter.provider.dart';

// The custom feature supplies German labels and an English fallback without
// altering upstream's generated translation catalog.
String _label(BuildContext context, String de, String en) =>
    Localizations.localeOf(context).languageCode == 'de' ? de : en;

class SharedAlbumFilterButton extends ConsumerWidget {
  final SharedAlbumView view;
  const SharedAlbumFilterButton({super.key, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(sharedAlbumSelectionProvider(view));
    final albums = ref.watch(sharedAlbumCatalogProvider).valueOrNull ?? [];
    final count = albums.where((album) => ids.contains(album.id)).length;
    return IconButton(
      tooltip: _label(context, 'Geteilte Alben', 'Shared albums'),
      icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.filter_alt_outlined)),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _AlbumFilterSheet(view: view),
      ),
    );
  }
}

class _AlbumFilterSheet extends ConsumerStatefulWidget {
  final SharedAlbumView view;
  const _AlbumFilterSheet({required this.view});

  @override
  ConsumerState<_AlbumFilterSheet> createState() => _AlbumFilterSheetState();
}

class _AlbumFilterSheetState extends ConsumerState<_AlbumFilterSheet> {
  late Set<String> _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = {...ref.read(sharedAlbumSelectionProvider(widget.view))};
  }

  Future<void> _save(List<({String id, String name})> albums) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(sharedAlbumSelectionProvider(widget.view).notifier)
          .save(_draft.intersection(albums.map((album) => album.id).toSet()));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_label(context, 'Auswahl konnte nicht gespeichert werden.', 'Could not save selection.')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(sharedAlbumCatalogProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _label(context, 'Geteilte Alben', 'Shared albums'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _label(
                  context,
                  'Eigene Fotos bleiben sichtbar. Identische Dateien erscheinen einmal.',
                  'Your own photos remain visible. Identical files appear once.',
                ),
              ),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(_label(context, 'Alben konnten nicht geladen werden.', 'Could not load albums.')),
                ),
                data: (albums) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : () => setState(() => _draft = albums.map((a) => a.id).toSet()),
                          child: Text(_label(context, 'Alle auswählen', 'Select all')),
                        ),
                        TextButton(
                          onPressed: _saving ? null : () => setState(() => _draft = {}),
                          child: Text(_label(context, 'Keine', 'None')),
                        ),
                      ],
                    ),
                    Expanded(
                      child: albums.isEmpty
                          ? Center(
                              child: Text(_label(context, 'Keine geteilten Alben vorhanden.', 'No shared albums.')),
                            )
                          : ListView.builder(
                              itemCount: albums.length,
                              itemBuilder: (_, index) {
                                final album = albums[index];
                                return CheckboxListTile(
                                  title: Text(album.name),
                                  value: _draft.contains(album.id),
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(() {
                                          value == true ? _draft.add(album.id) : _draft.remove(album.id);
                                        }),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: _saving ? null : () => _save(albums),
                        child: Text(
                          _label(context, _saving ? 'Speichern …' : 'Übernehmen', _saving ? 'Saving …' : 'Apply'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
