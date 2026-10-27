# Codestellen und Umsetzung

Die folgenden Pfade beziehen sich auf Immich v3.3.5. Der Patch enthält die Implementierung; automatisierte Prüfungen und Build-Nachweise stehen in `VALIDATION.md`. Ein Gerätetest steht aus.

| Pfad ab Immich-Repositorywurzel | Relevanz |
|---|---|
| mobile/lib/presentation/pages/dev/main_timeline.page.dart | Fotos-Hauptansicht und Filterbutton |
| mobile/lib/widgets/common/immich_sliver_app_bar.dart | App-Bar unterstützt zusätzliche Aktionen |
| mobile/lib/presentation/pages/map.page.dart | Direkter Einstieg zur Albumauswahl in der Karte |
| mobile/lib/providers/infrastructure/timeline.provider.dart | Auswahl an Timeline-Service weitergeben und neu laden |
| mobile/lib/providers/infrastructure/map.provider.dart | Auswahl an Kartenservice weitergeben |
| mobile/lib/domain/services/timeline.service.dart | Service-Erzeugung und gemeinsame Abfrageargumente |
| mobile/lib/domain/services/map.service.dart | Kartenabfrageargumente |
| mobile/lib/infrastructure/repositories/timeline.repository.dart | Assets, Buckets und Kartenbilderliste |
| mobile/lib/infrastructure/repositories/map.repository.dart | Kartenmarker und Filter |
| mobile/lib/data/db/main/query/merged_asset.drift | Hauptzeitleiste: entfernte/lokale Fotos und Bucketzählung |
| mobile/lib/data/db/main/table/remote/asset.dart | Prüfsumme, Eigentümer, Sichtbarkeit und Löschstatus |
| mobile/lib/data/db/main/table/remote/album.dart | Synchronisierte Alben |
| mobile/lib/data/db/main/table/remote/album_asset.dart | Asset-Album-Zuordnung |
| mobile/lib/data/db/main/table/remote/album_user.dart | Mitgliedschaft und Rollen |
| mobile/lib/domain/models/store.model.dart | Mögliche Ablage eigener Einstellungs-Keys |
| mobile/lib/domain/services/store.service.dart | Persistenter Store; endgültige Einbindung noch wählen |
| mobile/lib/presentation/widgets/map/map.state.dart | Kartenoptionen und Marker-Neuladen |
| mobile/lib/domain/models/map.model.dart | Kartenabfrageoptionen |
| mobile/lib/presentation/actions/ | Berechtigungen der Bildaktionen prüfen |
| mobile/mise.toml | Flutter-Version, Abhängigkeiten und Codegenerierung |
| mobile/android/app/build.gradle | Android-Paketkennung und Signierung |

## Umsetzungsbereiche

1. Gemeinsames Modell für die Albumauswahl und die gespeicherte Auswahl pro Ansicht definieren.
2. Geteilte, zugängliche Alben aus synchronisierten Daten bestimmen; Auswahl-UI ergänzen.
3. Gemeinsame Kandidaten- und Deduplizierungsregel in die Datenabfragen einbauen.
4. Hauptzeitleiste einschließlich lokaler Zuordnung, Buckets, Stapeln und Nachladen anpassen.
5. Marker und Kartenbilderliste einschließlich ihrer Filter anpassen.
6. Änderungsereignisse, Freigabeentzug und Aktionen auf fremden Bildern prüfen.
7. Tests, Analyse, Release-Build und reproduzierbare Patchdateien erstellen.

Bevor generierte Drift-/Freezed-Dateien verändert werden, die Quellmodelle ändern und die im jeweiligen Upstream vorgesehenen Generatoren ausführen.

## Implementierung des ersten Patches

- Neue Dateien `shared_album_sql.dart` und `shared_album_queries.dart` unter `mobile/lib/infrastructure/repositories/` enthalten gemeinsame Kandidaten-, Deduplizierungs-, Bucket-, Paging- und Markerabfragen. Die vorhandene `merged_asset.drift` bleibt unverändert; bei leerer Auswahl laufen die bisherigen Abfragen.
- `mobile/lib/domain/models/shared_album_preferences.dart` und `mobile/lib/providers/infrastructure/shared_album_filter.provider.dart` speichern getrennte ID-Auswahlen. Gespeichert wird erst nach erfolgreicher Datenbankoperation; gleichzeitige Schreibvorgänge der beiden Ansichten werden serialisiert.
- `mobile/lib/presentation/widgets/album/shared_album_filter_button.dart` enthält Button und Albumauswahl; Deutsch und Englisch als Fallback.
- `TimelineMapOptions` trägt die Auswahl sowohl zu den Markern als auch zur Kartenbilderliste. Synchronisierte Datenänderungen invalidieren zusätzlich die Markerabfrage.
- `mobile/android/app/build.gradle` ergänzt den eigenen App-Namen und die separate Paketkennung bei `IMMICH_SHARED_ALBUMS_BUILD=1`.
- Flutter-Integrationstests: `mobile/test/medium/repositories/shared_album_queries_test.dart`; Einstellungsserialisierung: `mobile/test/unit/shared_album_preferences_test.dart`.
- Keine Datenbankschemaänderung. Freezed-Code muss nach der Erweiterung von `TimelineMapOptions` neu generiert werden.

## Fremde Stapel bei reiner Albumfreigabe

Der Server sendet `stackId` in `syncAlbumAsset`, synchronisiert die eigentlichen Stapeldaten aber nur für den Eigentümer und Partner. Daher dürfen zusätzlich eingeblendete Albumfotos nicht vom Vorhandensein fremder Stack-Metadaten abhängen. Sie bleiben einzeln sichtbar; ihre DTOs enthalten in den erweiterten Ansichten keine fremde Stapel-ID. Die ursprünglichen Stapelregeln für die bestehende Eigentümer-/Partner-Auswahl bleiben erhalten.

Belege in v3.3.5: `server/src/database.ts` (`syncAlbumAsset`, `syncStack`), `server/src/repositories/sync.repository.ts` (`StackSync`, `PartnerStackSync`, `AlbumAssetSync`). Keine Serveränderung erforderlich.
