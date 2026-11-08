# PNG-Packer

Zwei kleine Shell-Skripte, die eine Datei oder einen Ordner als
**passwortgeschütztes ZIP** in ein PNG-Bild einbetten und wieder herausholen.

Das Bild bleibt dabei ein gültiges, ganz normal anzeigbares PNG – das ZIP
reist als zusätzlicher, privater PNG-Chunk (`flGn`) huckepack mit.

## Voraussetzungen

- `zip` / `unzip` (auf macOS vorinstalliert)
- `python3` (für die binäre Chunk-Bearbeitung; auf macOS vorhanden)

## Benutzung

### Einpacken

```bash
./pack.sh <quelle> <bild.png> <passwort> [ausgabe.png]
```

Beispiel:

```bash
./pack.sh FreeGuenther.app Bildschirmfoto.png 123456 Bild_mit_app.png
```

- `<quelle>` – Datei oder Ordner, der versteckt werden soll
- `<bild.png>` – Träger-Bild (bleibt unverändert; es wird eine Kopie erzeugt)
- `<passwort>` – Passwort für das ZIP
- `[ausgabe.png]` – optional; Standard ist `<bild>_packed.png`

### Auspacken

```bash
./unpack.sh <bild.png> <passwort> [zielordner]
```

Beispiel:

```bash
./unpack.sh Bild_mit_app.png 123456 ./entpackt
```

- `<bild.png>` – PNG mit eingebettetem ZIP
- `<passwort>` – Passwort des ZIP
- `[zielordner]` – optional; Standard ist das aktuelle Verzeichnis

## Wie es funktioniert

Ein PNG besteht aus einer Signatur und einer Folge von **Chunks**
(`[Länge][Typ][Daten][CRC]`), die mit dem `IEND`-Chunk endet.

`pack.sh`:
1. erstellt mit `zip -e` ein passwortgeschütztes ZIP der Quelle,
2. fügt dessen Bytes als eigenen Chunk vom Typ `flGn` direkt **vor** `IEND` ein.

`flGn` ist klein geschrieben = *ancillary* (optional) und *private*
(nicht standardisiert). Bildbetrachter kennen den Chunk nicht und
überspringen ihn – das Bild wird völlig normal angezeigt.

`unpack.sh` sucht den `flGn`-Chunk, schreibt die Bytes als ZIP heraus und
entpackt es mit dem angegebenen Passwort.

## Wichtige Hinweise

- **Fragil:** Der eingebettete Chunk überlebt kein erneutes Speichern in einem
  Bildprogramm, kein `optipng -strip all` und keinen Upload bei Diensten, die
  Bilder neu kodieren (Social Media, Messenger). Dabei geht das ZIP verloren.
- **Dateigröße:** Das PNG wächst um die Größe des ZIP. Aus einem kleinen Bild
  wird so leicht eine große Datei.
- **Schwache Verschlüsselung:** `zip -e` nutzt das klassische *ZipCrypto*, das
  gegen entschlossene Angreifer leicht zu knacken ist. Es schützt vor
  neugierigen Blicken, nicht als ernsthafte Sicherheit. Für echten Schutz
  stattdessen 7-Zip mit AES-256 verwenden (`7z a -mem=AES256 -p …`).

## Dateien

| Datei        | Zweck                                      |
|--------------|--------------------------------------------|
| `pack.sh`    | Quelle als passwortgeschütztes ZIP ins PNG |
| `unpack.sh`  | ZIP aus dem PNG holen und entpacken        |
