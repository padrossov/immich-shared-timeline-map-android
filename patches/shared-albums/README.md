# Shared-Albums-Patch für Immich2

Aktuelle Anleitung: [README-IMMICH2.md](../../README-IMMICH2.md).

Der Feature-Code ist im Fork-Branch `shared-albums` bereits angewendet und committiert. `build.sh` baut diesen Code direkt. `apply.py` und `0001-shared-albums.patch` dienen nur zum Übertragen auf einen sauberen Upstream-Checkout.

- `upstream.json`: Basisversion und Werkzeugversion.
- `REQUIREMENTS.md`, `CODE_MAP.md`: Anforderungen und Codestellen.
- `PORTING.md`: Übertragung auf neue Versionen.
- `VALIDATION.md`: historische Build-Nachweise und manuelle Prüffälle.
- `release.json`: Metadaten der früheren, vom Nutzer erfolgreich getesteten APK namens Immich Shared; kein Nachweis des neuen Fork-Builds.
- `verify_sql.py`: 18 SQL-Regressionstests.
- `build.sh`: Codegenerierung, Analyse, Flutter-Tests und ARM64-Release-Build.

Anzeigename des neuen Builds: **Immich**. Paketkennung bleibt `app.alextran.immich.sharedalbums`.
