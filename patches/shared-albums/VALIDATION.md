# Validierung

Status: Aktueller Release-Build und Signaturprüfung erfolgreich. Flutter-Analyse ohne Probleme, 15 Flutter-Tests und 18 SQL-Prüfungen bestanden. Die folgende vollständige Prüfliste enthält auch manuelle Fälle; ein Android-Gerätetest steht noch aus.

## Prüffälle je Zielversion

- [ ] Keine Alben ausgewählt: bisheriges Verhalten in Fotos und Karte.
- [ ] Ein Album, mehrere Alben, alle und keines; eigene und fremde Album-Eigentümer.
- [ ] Auswahl für Fotos und Karte unabhängig; Neustart, Server- und Kontowechsel.
- [ ] Neue, umbenannte und gelöschte Alben; Umgang mit ungültig gewordenen gespeicherten IDs.
- [ ] Ein Asset in mehreren Alben nur einmal.
- [ ] Identische Datei bei mehreren Nutzern: eigenes zulässiges Exemplar bevorzugt, sonst stabile Auswahl.
- [ ] Nur ähnliche Dateien bleiben getrennt.
- [ ] Ein unsichtbares/gelöschtes/ausgefiltertes Duplikat verdrängt kein zulässiges Foto.
- [ ] Nicht ausgewählte Alben und weitere private Bilder desselben Eigentümers erscheinen nicht.
- [ ] Lokale Kopie und entferntes Asset, Stapel und Stapel-Primärbild.
- [ ] Tages-/Monatsgruppen, Zählungen, Scrubber, Seitengrenzen und Nachladen konsistent.
- [ ] Karte: GPS fehlt, gleicher Standort mehrerer verschiedener Bilder, Ausschnittwechsel.
- [ ] Karte: Zeitraum, Favoriten und Archiv; Marker und Bilderliste stimmen überein.
- [ ] Albumfoto entfernt und Freigabe entzogen: nach Synchronisierung ausgeblendet, auch wenn das Asset noch lokal bekannt ist.
- [ ] Fremde Bilder: Einzelansicht und Mehrfachauswahl; Löschen, Archivieren und Bearbeiten respektieren Rechte.
- [ ] Größere Bibliothek: Abfragezeit und Speichernutzung prüfen.
- [ ] Flutter-Analyse, passende automatisierte Tests und erfolgreicher Android-Release-Build.
- [ ] APK installiert und Auswahl sowie Bildanzeige auf Android geprüft.

## Nachweise

Für jede tatsächlich geprüfte Version einen Abschnitt ergänzen mit: Immich-Tag und Commit, Patch-Commit, Werkzeugversionen, Testbefehlen und Ergebnissen, Android-Testgerät, Build-ID/-Link, APK-Prüfsumme und offenen Einschränkungen.

Der aktuelle automatisierte Nachweis für v3.3.5 steht am Ende dieser Datei; manuelle Prüfungen sind dadurch nicht automatisch bestätigt.

## Lokaler Nachweis vom 2026-10-27

- Vorgesehener Upstream: v3.3.5 / `8303cb117e197c700332b33b61b45314c9cc5bb4`.
- `python3 patches/shared-albums/verify_sql.py <quellcode> --dart <dart>`: 17 Tests erfolgreich, zusätzlich Serialisierung der Auswahl geprüft.
- Werkzeug: Dart 3.13.2 aus der lokalen Laufzeit; dies ersetzt keinen Build mit der geforderten Flutter-Version 3.47.2.
- Getestet wurden die tatsächlich vom Dart-Code erzeugten SQL-Abfragen auf einer SQLite-Testdatenbank. Die Prüfung ersetzt keine Integrationstests mit Immichs Drift-Datenbank oder einen Android-Gerätetest.
- `git diff --check`, Bash-Syntax und Python-Syntax geprüft.
- Die vollständige Flutter-Prüfung ist als Voraussetzung des APK-Builds im Workflow eingerichtet, aber noch nicht als erfolgreich nachgewiesen.

## CI-Prüfung auf Commit 525c890

- Lauf: https://github.com/padrossov/ImmichApk/actions/runs/40496782686
- Patchanwendung auf dem vollständigen Upstream-Checkout: erfolgreich.
- Codegenerierung: erfolgreich.
- Flutter-Analyse und ausgewählte Flutter-Tests: erfolgreich.
- APK-Kompilierung: Runner abgebrochen, kein abrufbares Abschlussprotokoll und keine APK. Die Ursache ist nicht bestätigt.
- Folgelauf begrenzt Gradle/Kotlin-Parallelität und Speicher, ergänzt Swap bei ausreichendem Platz und lädt ein separates Buildprotokoll hoch.

## CI-Prüfung auf Commit abdb8b0

- Lauf: https://github.com/padrossov/ImmichApk/actions/runs/40500256266
- Codegenerierung und Flutter-Analyse: erfolgreich, keine Analyseprobleme.
- 14 Flutter-Tests und 17 SQL-Prüfungen: erfolgreich.
- APK-Build gescheitert: `No space left on device`; vor dem Build waren nur 8,5 GiB frei. Das Log bestätigt den Platzmangel beim Download von Android-/Kotlin-Abhängigkeiten.
- Folgelauf entfernt ausschließlich ungenutzte vorinstallierte Toolchains und Images des temporären GitHub-Runners und prüft mindestens 25 GiB freien Platz vor dem Setup.

## CI-Prüfung auf Commit d4ed530

- Lauf: https://github.com/padrossov/ImmichApk/actions/runs/40502077840
- Vor dem Android-Build waren 28 GiB frei; zusätzlicher Swap wurde erfolgreich eingerichtet.
- Codegenerierung, Analyse, 14 Flutter-Tests und 17 SQL-Prüfungen bestanden.
- Android-Fehler: `GeneratedPluginRegistrant.java` registrierte `IntegrationTestPlugin`, während das Plugin im Release-Gradle-Projekt nicht enthalten war.
- Ursache anhand Flutter 3.47.2 bestätigt: `--no-pub` verhindert die Neuerzeugung plattformspezifischer Plugin-Dateien für den Release-Modus. Die Buildoption wurde entfernt.
- Referenzen: https://github.com/flutter/flutter/blob/3.47.2/packages/flutter_tools/lib/src/runner/flutter_command.dart und https://github.com/flutter/flutter/blob/3.47.2/packages/flutter_tools/lib/src/flutter_plugins.dart
- Gradle-Cache ergänzt, damit weitere Builds/Korrekturen vorhandene Android-Abhängigkeiten wiederverwenden können.

## Zusätzliche Prüfung fremder Stapel

- Im Servercode bestätigt: Album-Asset-Synchronisierung enthält Stapel-IDs, während Stapeldaten nur für Eigentümer und Partner synchronisiert werden.
- Kandidatenregel korrigiert: Reine Albumfotos bleiben auch bei fehlender fremder Stapeldefinition oder einem außerhalb der Auswahl liegenden Primärbild sichtbar; eigene und bereits eingeblendete Partnerbilder bleiben nach der bisherigen Stapellogik gefiltert.
- Private Stapel-IDs bei zusätzlich eingeblendeten Albumfotos aus den Ansichts-DTOs entfernt.
- SQL-Regressionstest ergänzt: Fremdes freigegebenes Stapelbild sichtbar, privates Primärbild bleibt außerhalb der Auswahl.
- Neuer Drift-/Flutter-Test prüft Anzeige, Zählung und fehlende private Stapel-ID.
- Lokal: 18 SQL-Prüfungen erfolgreich. Die Flutter-Prüfung des aktualisierten Patches steht noch aus.

## Erster erfolgreicher APK-Kompilierschritt

- Commit `0aa4c2c`, Lauf https://github.com/padrossov/ImmichApk/actions/runs/40505290943.
- `flutter build apk --release` erfolgreich: `app-release.apk`, laut Buildausgabe 100,2 MB.
- Danach schlug die gesonderte Abfrage des Entwicklungs-Keystores fehl. Deshalb wurde noch keine APK zum Download hochgeladen; dieser Lauf ist kein Auslieferungsnachweis.
- Zertifikatsprüfung auf die tatsächlich erzeugte APK mit Androids `apksigner verify --print-certs` umgestellt; optionaler Cache-Upload folgt erst nach Bereitstellung der APK.
- CI verwendet bei fehlendem eigenem Keystore nun einen ausdrücklich angelegten, gecachten Entwicklungs-Keystore und kopiert ihn in die von Immichs Release-Signierung erwartete Datei. Der private Schlüssel wird weder ins Repository noch in Download-Artefakte aufgenommen.

## Erfolgreicher Abschluss: Commit c318e61

- Basis: Immich v3.3.5 / `8303cb117e197c700332b33b61b45314c9cc5bb4`.
- Patch-/Build-Projekt: `c318e615b9746049a6b9941681f52220680dd84b`.
- Workflow: https://github.com/padrossov/ImmichApk/actions/runs/40510940616 — erfolgreich.
- Codegenerierung, Flutter-Analyse ohne Probleme, 15 Flutter-Tests und 18 SQL-Prüfungen erfolgreich.
- ARM64-Release-APK: 100.180.269 Bytes.
- APK SHA-256: `2fe66f19fbd104bb72e6221f01204890e4a29ee38ed0aa2df08d0c27deb09727`.
- APK-Signatur direkt geprüft: APK Signature Scheme v2 gültig, ein Entwicklungssignierer.
- Zertifikat SHA-256: `154199b39a2bbdc1d3bba4996b430639b23035005f960d007accb469aa7afc79`.
- Heruntergeladene Datei stimmt mit der im Build erzeugten SHA-256 überein. AndroidManifest, DEX und ARM64-Flutter-App-Bibliothek vorhanden.
- Die letzte Änderung war die Sichtbarkeit fremder Stapelbilder und das Entfernen ihrer privaten Stapel-ID in den ergänzten Ansichten; der zusätzliche Flutter-Test wurde erfolgreich ausgeführt.
- Download: https://github.com/padrossov/ImmichApk/actions/runs/40510940616/artifacts/12738520565
- Offene Einschränkung: Kein Test auf einem Android-Gerät und keine vollständige manuelle Prüfung aller oben aufgeführten Fälle. Entwicklungssignatur, separate Installation als „Immich Shared“.

## Nutzerbestätigung und Fork-Migration am 27.10.2026

- Nutzer: „Apk funktioniert wie erwartet“. Kein vollständiger manueller Prüfkatalog bestätigt.
- Feature auf identischer Basis v3.3.5 als Code-Commit in den Fork übernommen.
- Anzeigename für den nächsten Build: Immich. Paketkennung und erwarteter Signierer bleiben identisch.
- Ergebnisse des neuen Fork-Builds sind gesondert zu erfassen.

## Erfolgreicher Fork-Release-Build mit Anzeigename Immich

- Quellcode: `642e50ecf5361afb08fbc3155dff58eaee9c993f` in `padrossov/immich-shared-timeline-map-android`.
- Workflow: https://github.com/padrossov/ImmichApk/actions/runs/40525890651 — erfolgreich.
- Codegenerierung und Flutter-Analyse ohne Probleme; 15 Flutter-Tests und 18 SQL-Prüfungen bestanden.
- ARM64-Release-APK: 100180261 Bytes.
- SHA-256: `2a51d271b3ecfe3c258bfb9554c939d26a544d494ded0c9688399bdef4de01b5`, nach Download bestätigt.
- APK-Signatur v2 gültig; bisheriges Zertifikat `154199b39a2bbdc1d3bba4996b430639b23035005f960d007accb469aa7afc79` unverändert.
- Getrennte Paketkennung `app.alextran.immich.sharedalbums`, Anzeigename **Immich**.
- Neuer Gerätetest steht aus. Der Nutzer bestätigte zuvor die Funktion der ursprünglichen Feature-APK.
