# Wartung im Fork

Im Branch `shared-albums` liegen die Änderungen als echte Git-Commits auf v3.3.5. Für neue Versionen bevorzugt einen Arbeitsbranch davon anlegen und den gewünschten stabilen Upstream-Tag mergen. Konflikte auflösen, Werkzeugversionen prüfen und Build/Tests ausführen. Anschließend die Patchdatei gegen die neue Basis exportieren und ihre Anwendbarkeit auf einem sauberen Checkout prüfen. Die Patchdatei wird im Fork-Build nicht erneut angewendet.

Der Build wird zur Nutzung des vorhandenen Signierungscaches aktuell im Repository ImmichApk ausgelöst und ruft den Workflow aus diesem Fork mit festem Commit auf. Nach einem Versionsupdate dessen Workflow-Referenz und `source_ref` auf den neuen geprüften Commit setzen. Anleitung und Signierung: [README-IMMICH2.md](../../README-IMMICH2.md).

---

# Auf spätere Immich-Versionen übertragen

## Voraussetzungen

Die erste Implementierung liegt in `0001-shared-albums.patch` vor. Ihr vollständiger Flutter-/Android-Prüfstatus steht in `VALIDATION.md`; für v3.3.5 sind ein erfolgreicher Release-Build und die Signaturprüfung bestätigt. Der Gerätetest steht aus.

## Ausgangsversion reproduzieren

1. Immich in einem separaten Checkout auschecken.
2. Den vollständigen Commit aus `upstream.json` verwenden und einen sauberen Arbeitsbaum prüfen.
3. Alle nicht kommentierten Einträge aus `series` in der angegebenen Reihenfolge lesen.
4. Vor dem Anwenden mit `git apply --check <patchdatei>` prüfen; dann mit `git apply <patchdatei>` anwenden. Bei mehreren Dateien jede nächste auf dem Stand nach ihrer Vorgängerdatei prüfen.
5. Eine leere Liste ausdrücklich als „kein Patch vorhanden“ behandeln.

Die Pfade in den Patchdateien beziehen sich auf die Wurzel des Immich-Checkouts. Keine unscharfe Anwendung, ignorierten Fehler oder stillschweigend übersprungenen Teile verwenden.

## Neue Zielversion

1. Ziel-Tag und vollständigen Commit festhalten; zuerst in einem separaten Branch/Checkout arbeiten.
2. Neue Flutter-/Dart-/Android-Anforderungen aus dem Zielcode lesen. Den Workflow-Einstieg ebenfalls an die neue Basis anpassen: Checkout-Commit, Flutter-/Node-/Java-/Generator-Versionen und versionsbezogene Cache-Keys.
3. Patchanwendung prüfen und Konflikte gezielt auflösen.
4. Auch bei konfliktfreier Anwendung die Datenwege aus `CODE_MAP.md` prüfen: Synchronisierung, Prüfsummen, Mitgliedschaften, Sichtbarkeit, Stapel, lokale Zuordnung, Zählungen und Paging.
5. Quellmodelle und Abfragen anpassen und den Upstream-Codegenerierungsablauf ausführen.
6. `VALIDATION.md` abarbeiten. Testbefehle, Ergebnisse und Einschränkungen eintragen.
7. Erst nach erfolgreicher Prüfung die neue Basis in `upstream.json` übernehmen und die Patchdateien neu exportieren. Den vorherigen Stand über Git erhalten.
8. Version und Commit der Zielbasis, Patch-Commit, Werkzeugversionen, Paketkennung und Signierungszertifikat zum Build festhalten.

## Patchdateien erzeugen

Kleine, thematisch zusammengehörige Commits erleichtern die Übertragung. Die vollständige Differenz muss neue Dateien und Tests einschließen.

Für ein Arbeitsverzeichnis mit bereits committierten, ausschließlich zu diesem Feature gehörenden Änderungen:

```bash
git diff --binary <upstream-commit> HEAD -- mobile i18n > /pfad/zu/ImmichApk/patches/shared-albums/0001-shared-albums.patch
```

Weitere veränderte Pfade ausdrücklich ergänzen. Danach die exportierten Dateien auf einem frischen Checkout anwenden und nochmals prüfen. `series` mit den tatsächlichen Dateinamen pflegen. Generierte Dateien gemäß Upstream-Konvention behandeln.

## Android-Release-Build

- Abhängigkeiten und Codegenerierung aus den Buildanweisungen der gewählten Immich-Version übernehmen.
- Flutter-Analyse, relevante Datenbank-/Provider-/Widgettests und anschließend `flutter build apk --release` ausführen.
- Paketkennung und Anzeigenamen für die eigene APK bewusst festlegen.
- Ein eigenes, dauerhaft gleiches Signierungszertifikat verwenden und dessen Fingerabdruck dokumentieren. Schlüssel und Passwörter gehören nicht ins Repository.
- Eigene Signatur ermöglicht kein Update über die offizielle Play-Store-Signatur. Installationsweg vor der ersten Ausgabe festlegen.
- `--release` bezeichnet den Buildmodus und bestätigt weder eigene Release-Signierung noch Veröffentlichung.
- APK-Prüfsumme und Buildprotokoll zur konkreten Version festhalten. Eine APK erst als fertig melden, wenn der Build erfolgreich beendet ist.

## Automatisierter Ablauf

`apply.py` prüft standardmäßig den exakten Upstream-Commit und einen sauberen Arbeitsbaum. `--allow-other-base` ist ausschließlich für einen bewussten Übertragungsversuch vorgesehen; auch dann bleibt `git apply --check` verbindlich.

`build.sh` benötigt Flutter 3.47.2, Java, Android SDK und `openapi-generator-cli` in der von Upstream festgelegten Version. Der Workflow richtet diese Werkzeuge auf GitHub Actions ein. Er baut ARM64 für moderne Android-Geräte. Die APK wird erst nach erfolgreicher Analyse und Tests als Actions-Artefakt hochgeladen.
