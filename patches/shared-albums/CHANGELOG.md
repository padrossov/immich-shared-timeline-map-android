# Änderungsverlauf

## 2026-10-27

- Eigenen Ordner für das Shared-Albums-Patchpaket angelegt.
- Vereinbarte Anforderungen, bekannte Codestellen, Übertragungsablauf und Prüffälle zusammengeführt.
- Vorgesehene Basis v3.3.5 mit vollständigem Commit und Flutter-Anforderung erfasst.
- Implementierung, Patchdateien und Release-APK stehen aus.

### Erste Implementierung

- Albumfilter mit Mehrfachauswahl, „alle aktuell vorhandenen“ und „keine“ direkt in Fotos und Karte.
- Auswahl getrennt pro Ansicht und Server/Konto persistent gespeichert.
- Gemeinsame SQL-Auswahl mit Prüfsummen-Deduplizierung vor Zählungen und Seiteneinteilung.
- Kartenmarker, Kartenbilderliste, lokale Zuordnung und synchronisierter Freigabeentzug berücksichtigt.
- 17 lokal bestandene SQL-Prüfungen und Flutter-Integrationstests hinzugefügt.
- Reproduzierbaren Patch, Anwendungsskript und Release-Build-Workflow ergänzt.
- Eigene Paketkennung für parallele Installation; Entwicklungszertifikat als derzeitiger Fallback dokumentiert.
- Flutter-/Android-Prüfung und Gerätetest stehen aus.

### Korrekturen nach erstem CI-Lauf

- Testimport für `isNotNull` und Importreihenfolge bereinigt; Pattern-Variablen als `final` deklariert.
- Veraltete Build-Runner-Option entfernt.
- Codegenerierung, Analyse/Tests und APK-Build als getrennte Workflow-Schritte sichtbar gemacht.

### Build-Runner

- Nach erfolgreicher Flutter-Analyse und Tests brach der Runner während der APK-Kompilierung ab; Ursache mangels abrufbarer Logs unbestätigt.
- Gradle-Speicher/Parallelität begrenzt, Kotlin im Gradle-Prozess, Swap und separate Builddiagnose ergänzt.

### Platzbedarf des Android-Builds

- Runner-Plattenplatz als bestätigte Ursache des nächsten Abbruchs identifiziert.
- Cleanup ungenutzter vorinstallierter Toolchains/Images im kurzlebigen CI-Runner und Mindestplatzprüfung vor dem Setup ergänzt.
- 14 Flutter-Tests, 17 SQL-Prüfungen und Flutter-Analyse erfolgreich bestätigt.

### Release-Pluginregistrierung

- `--no-pub` vom APK-Build entfernt, damit Flutter nach den Tests die Pluginregistrierung für Release neu erzeugt und Testplugins ausschließt.
- Persistenten Android-Compiler-Cache für nachfolgende Builds ergänzt.

### Fremde Fotostapel

- Zusätzlich eingeblendete Albumfotos nicht mehr durch fehlende, privat gebliebene Stapeldefinitionen ausblenden.
- Bestehende Eigentümer-/Partnerstapel unverändert behandeln; zusätzliche Albumfotos ohne private Stapel-ID anzeigen.
- Regressionstests für Sichtbarkeit, Zählung und Ausschluss des privaten Primärbildes ergänzt; lokal nun 18 SQL-Prüfungen bestanden.

### Signaturprüfung und Ausgabe

- Erfolgreiche erste Release-Kompilierung (100,2 MB); Zertifikats-Metadatenschritt verhinderte noch die Ausgabe.
- Signatur nun direkt an der APK mit `apksigner` prüfen; Entwicklungs-Keystore für CI explizit setzen.
- APK vor dem optionalen Cache-Upload bereitstellen.

### Verifizierter Release-Build

- Workflow für Commit `c318e61` vollständig erfolgreich abgeschlossen.
- Flutter-Analyse, 15 Flutter-Tests und 18 SQL-Prüfungen erfolgreich.
- ARM64-APK gebaut, Signatur direkt geprüft, Download bereitgestellt und APK-Prüfsumme nach dem Herunterladen bestätigt.
- Build-Provenienz und Prüfsummen in `release.json` erfasst. Android-Gerätetest steht aus.

### Fork und Immich2

- Getesteten Patch als echte Code-Commits im Branch `shared-albums` auf v3.3.5 übernommen.
- Anzeigename auf Immich geändert; Paketkennung für Aktualisierungen beibehalten.
- Nutzer meldete die bisherige APK als erwartungsgemäß funktionierend.
- Neuer Build verwendet den Fork direkt und prüft den bisherigen Signaturfingerabdruck.
