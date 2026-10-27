# Immich — Android-Fork mit geteilten Alben

[APK unter Releases herunterladen](https://github.com/padrossov/immich-shared-timeline-map-android/releases/latest) · [APK bauen und veröffentlichen](https://github.com/padrossov/immich-shared-timeline-map-android/actions/workflows/immich2-release.yml)

## Ablauf

1. **Actions → Build and publish Immich APK → Run workflow** öffnen.
2. Workflow-Branch **main** wählen. Unter `source_ref` steht standardmäßig **shared-albums**; hier kann auch ein eigener Branch, Tag oder Commit dieses Forks gewählt werden.
3. Nach Codegenerierung, Analyse, Tests und erfolgreichem ARM64-Release-Build erscheint die APK automatisch unter **Releases**. APK, SHA256SUMS, Zertifikatsdaten und Build-Metadaten werden veröffentlicht.
4. Änderungen an App-Code, SDK, Übersetzungen oder Patchwerkzeugen in `shared-albums` starten denselben Ablauf automatisch. Reine Dokumentationsänderungen starten keinen Build.

Der Anzeigename ist **Immich**, die Paketkennung bleibt `app.alextran.immich.sharedalbums`. Die offizielle Play-Store-App kann parallel installiert bleiben.

## Einmalige Signierungseinrichtung

Für neue Builds muss im Fork unter **Settings → Secrets and variables → Actions → New repository secret** das Secret **ANDROID_KEYSTORE_BASE64** mit der Base64-Kodierung des bisherigen Keystores eingerichtet werden. Der frühere Name `IMMICH2_KEYSTORE_BASE64` wird ebenfalls akzeptiert.

Es muss der vorhandene Schlüssel aus dem bisherigen ImmichApk-Build sein: Alias `androiddebugkey`, bisherige Keystore-/Schlüsselpasswörter und Zertifikat SHA-256 `154199b39a2bbdc1d3bba4996b430639b23035005f960d007accb469aa7afc79`. Der Workflow prüft den Fingerabdruck vor dem Build. Ohne den Schlüssel stoppt er, statt eine nicht aktualisierbare APK auszugeben. Der private Schlüssel wird nicht in Git, öffentliche Caches oder Release-Downloads aufgenommen.

**Stand dieser Einrichtung:** Der Workflow ist vorbereitet; die Übernahme des Secrets aus dem alten Repository ist noch erforderlich. Die bereits geprüfte APK ist unabhängig davon als Release veröffentlicht.

## Versionen aktualisieren

`shared-albums` enthält den produktiven App-Code samt Feature-Commits auf Basis von v3.3.5. Neue stabile Immich-Tags zuerst in einen Arbeitsbranch davon mergen, Konflikte lösen und Werkzeugversionen im Workflow prüfen. Danach in `shared-albums` übernehmen und den Build prüfen.

`main` enthält die Workflow-Einstiege für GitHubs Actions-Oberfläche und ansonsten die Upstream-Linie. `main` allein zu synchronisieren aktualisiert den Feature-Branch nicht. Die APK wird aus `source_ref` bzw. bei einem Push aus dem konkreten Feature-Commit gebaut; der veröffentlichte Release-Tag verweist auf genau diesen Quellcommit.

Das transportierbare Patchpaket, SQL-/Flutter-Tests und historische Nachweise liegen in `patches/shared-albums/`. Der Patch wird im Fork-Build nicht erneut angewendet.

## Bestehender Release

Die erste Ausgabe `v3.3.5-shared-albums.1` veröffentlicht die bereits geprüfte APK aus Quellcommit `642e50ecf5361afb08fbc3155dff58eaee9c993f`. Codegenerierung, Flutter-Analyse, 15 Flutter-Tests, 18 SQL-Prüfungen und Signaturprüfung bestanden; SHA-256 nach Download bestätigt. Die Veröffentlichung ist kein neuer Build. Ein Gerätetest dieser konkreten APK steht aus; der Nutzer bestätigte die Funktion der vorherigen Feature-APK.
