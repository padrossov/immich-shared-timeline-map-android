# Vereinbarter Funktionsumfang

## Bedienung

- Je ein kleiner Albumfilter-Button direkt im Fotos-Tab und in der Karte.
- Kein zusätzlicher Menüpunkt „Sonderfunktionen“.
- Geteilte Alben einzeln, alle oder keines auswählen.
- Anfangs keine zusätzlichen Alben ausgewählt; „keines“ stellt die bisherige Ansicht wieder her.
- Auswahl für Fotos und Karte getrennt und über App-Neustarts hinweg speichern.
- Gespeicherte Auswahl einem Server und angemeldeten Nutzer zuordnen, damit ein Kontowechsel keine fremde Auswahl übernimmt.
- Albumliste und Inhalte nach synchronisierten Änderungen aktualisieren.
- „Alle auswählen“ speichert die aktuell angezeigten Album-IDs. Später neu geteilte Alben werden nicht automatisch hinzugefügt.

## Sichtbare Fotos

- Eigene und bisher eingeblendete Partnerbilder als Basis beibehalten.
- Nur Bilder aus den ausgewählten, für den Nutzer zugänglichen geteilten Alben ergänzen. Weitere Bilder desselben Eigentümers dürfen nicht erscheinen.
- Öffentliche Freigabelinks gehören nicht zum Funktionsumfang.
- Dasselbe Asset in mehreren Alben anhand seiner Immich-ID nur einmal berücksichtigen.
- Bei unterschiedlichen Assets mit identischer Datei die synchronisierte Prüfsumme verwenden. Ähnliche, aber nicht dateigleiche Bilder bleiben getrennt.
- Repräsentanten ausschließlich aus den für die jeweilige Ansicht zulässigen Kandidaten wählen: eigenes Exemplar bevorzugen, sonst feste Reihenfolge anhand der Asset-ID.
- Vorhandene Regeln für Papierkorb und Sichtbarkeit berücksichtigen. Gesperrte Bilder dürfen nicht eingeblendet werden.
- Eigene und bereits eingeblendete Partnerstapel behalten die bisherige Primärbild-Regel. Zusätzlich eingeblendete Albumfotos werden einzeln dargestellt, weil reine Albumfreigaben keine fremden Stapeldaten synchronisieren; der Bildbetrachter erhält dafür keine private Stapel-ID.
- Deduplizierung darf keine Veränderung oder Löschung von Dateien auf dem Server auslösen.
- Bei ausgeschalteter Albumergänzung das bisherige Verhalten beibehalten.

## Konsistenz und Rechte

- Sichtbare Assets vor Zählung und Seiteneinteilung bestimmen.
- Für Karte, zugehörige Bilderliste und Zählungen dieselben Regeln verwenden.
- Bestehende Kartenfilter für GPS, Ausschnitt, Zeitraum, Favoriten und Archiv berücksichtigen; ein ungeeigneter Duplikat-Repräsentant darf ein passendes Bild nicht verdrängen.
- Lokale Fotozuordnung berücksichtigen; keine zusätzliche Anzeige derselben lokalen und entfernten Datei.
- Entfernte Albumbilder, gelöschte Alben und entzogene Mitgliedschaften nach erfolgreicher Synchronisierung übernehmen.
- Aktionen auf fremden Bildern auf bestehende Berechtigungen begrenzen; Einzelansicht und Mehrfachauswahl prüfen.
- Keine Serveränderung vorgesehen. Vor Implementierung und bei Versionswechseln den Synchronisierungsvertrag erneut prüfen.
