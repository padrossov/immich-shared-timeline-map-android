# Immich Shared

Android-App auf Basis von Immich v3.3.5 mit getrennten Albumfiltern für Fotos und Karte sowie Prüfsummen-Deduplizierung.

## Branches und Updates

- `main`: unveränderte Upstream-Linie.
- `shared-albums`: produktiver App-Code einschließlich Feature-Commits und Build.
- Änderungen liegen direkt im Quellcode. Beim Bauen wird keine Patchdatei erneut angewendet.
- Neue stabile Immich-Versionen in `shared-albums` mergen, Konflikte lösen und Analyse, Tests und Release-Build ausführen. `main` allein zu synchronisieren aktualisiert die App nicht.
- `patches/shared-albums/`: portierbares Patchpaket, Tests, Buildskript und Nachweise. Der Patch ist zum Anwenden auf eine unveränderte Basis gedacht, nicht auf den bereits gepatchten Branch.

## Release-Build und Signierung

Der Workflow `.github/workflows/immich2-release.yml` baut den gewählten Fork-Stand direkt. Der derzeitige Build wird vom bisherigen Repository **padrossov/ImmichApk** über einen kleinen Aufruf-Workflow gestartet. Dadurch bleibt dessen vorhandener Signierungscache nutzbar und die APK kann die bereits installierte Variante aktualisieren.

Anzeigename: **Immich Shared**. Paketkennung: `app.alextran.immich.sharedalbums`. ARM64, Release-Modus.

Ein direkter Lauf im neuen Fork benötigt denselben Keystore über das Secret `IMMICH2_KEYSTORE_BASE64`. Der Workflow erzwingt den bisherigen Zertifikat-Fingerabdruck und erzeugt keinen Ersatzschlüssel. Der Cache ist keine dauerhafte Schlüsselsicherung. Private Schlüssel gehören nicht in Git oder Download-Artefakte.

Download nach erfolgreichem Lauf: **Actions → Build Immich2 release APK → Artifacts → Immich-3.3.5-shared-albums-arm64-release**.

## Prüfstatus

Die vorherige APK bestand Flutter-Analyse, 15 Flutter-Tests, 18 SQL-Prüfungen und Signaturprüfung. Der Nutzer bestätigte am 27.10.2026, dass sie wie erwartet funktioniert. Das bestätigt keinen vollständigen Durchlauf der manuellen Prüfliste. Der neue Fork-Build wird gesondert geprüft; `release.json` dokumentiert bis dahin ausschließlich die frühere APK.
