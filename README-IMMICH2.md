# Immich — Android-Fork mit geteilten Alben

[APK unter Releases herunterladen](https://github.com/padrossov/immich-shared-timeline-map-android/releases/latest) · [APK bauen und veröffentlichen](https://github.com/padrossov/immich-shared-timeline-map-android/actions/workflows/immich2-release.yml)

## Ablauf

1. **Actions → Build and publish Immich APK → Run workflow** öffnen.
2. Workflow-Branch **main** wählen. Unter `source_ref` steht standardmäßig **shared-albums**; hier kann auch ein eigener Branch, Tag oder Commit dieses Forks gewählt werden.
3. Nach Codegenerierung, Analyse, Tests und erfolgreichem ARM64-Release-Build erscheint die APK automatisch unter **Releases**. APK, SHA256SUMS, Zertifikatsdaten und Build-Metadaten werden veröffentlicht.
4. Änderungen an App-Code, SDK, Übersetzungen oder Patchwerkzeugen in `shared-albums` starten denselben Ablauf automatisch. Reine Dokumentationsänderungen starten keinen Build.

Der Anzeigename ist **Immich**, die Paketkennung bleibt `app.alextran.immich.sharedalbums`. Die offizielle Play-Store-App kann parallel installiert bleiben.

## Signierung der Release-APK

Ab v3.3.6 verwendet der Fork einen eigenen dauerhaften Signaturschlüssel. Der Workflow liest den Keystore aus dem Actions-Secret `ANDROID_RELEASE_KEYSTORE_BASE64` im Fork und prüft das Zertifikat vor dem Build sowie an der fertigen APK.

Den SHA-256-Fingerabdruck des öffentlichen Zertifikats als Repository-Variable `ANDROID_RELEASE_CERT_SHA256` hinterlegen.

Beim Umstieg von der früheren Signatur muss die bisherige gepatchte App einmal deinstalliert werden. Spätere Builds mit diesem Zertifikat lassen sich als Update installieren.

## Versionen aktualisieren

`shared-albums` enthält den produktiven App-Code samt Feature-Commits auf Basis von v3.3.6. Neue stabile Immich-Tags zuerst in einen Arbeitsbranch davon mergen, Konflikte lösen und Werkzeugversionen im Workflow prüfen. Danach in `shared-albums` übernehmen und den Build prüfen.

`main` enthält die Workflow-Einstiege für GitHubs Actions-Oberfläche und ansonsten die Upstream-Linie. `main` allein zu synchronisieren aktualisiert den Feature-Branch nicht. Die APK wird aus `source_ref` bzw. bei einem Push aus dem konkreten Feature-Commit gebaut; der veröffentlichte Release-Tag verweist auf genau diesen Quellcommit.

Das transportierbare Patchpaket, SQL-/Flutter-Tests und historische Nachweise liegen in `patches/shared-albums/`. Der Patch wird im Fork-Build nicht erneut angewendet.

## Bestehender Release

Die erste Ausgabe `v3.3.5-shared-albums.1` veröffentlicht die bereits geprüfte APK aus Quellcommit `642e50ecf5361afb08fbc3155dff58eaee9c993f`. Codegenerierung, Flutter-Analyse, 15 Flutter-Tests, 18 SQL-Prüfungen und Signaturprüfung bestanden; SHA-256 nach Download bestätigt. Die Veröffentlichung ist kein neuer Build. Ein Gerätetest dieser konkreten APK steht aus; der Nutzer bestätigte die Funktion der vorherigen Feature-APK.
