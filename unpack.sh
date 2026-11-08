#!/usr/bin/env bash
#
# unpack.sh – zieht das in einem PNG versteckte ZIP ("flGn"-Chunk) heraus
#             und entpackt es mit dem Passwort.
#
# Benutzung:
#   ./unpack.sh <bild.png> <passwort> [zielordner]
#
# Beispiel:
#   ./unpack.sh Bild_mit_app.png 123456 ./entpackt
#
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Benutzung: $0 <bild.png> <passwort> [zielordner]" >&2
  exit 1
fi

PNG_IN="$1"
PASS="$2"
DEST="${3:-.}"

[ -f "$PNG_IN" ] || { echo "Fehler: Bild '$PNG_IN' nicht gefunden." >&2; exit 1; }
mkdir -p "$DEST"

TMPZIP="$(mktemp -t unpackzip).zip"
trap 'rm -f "$TMPZIP"' EXIT

echo "[1/2] ZIP aus PNG extrahieren ..."
PNG_IN="$PNG_IN" TMPZIP="$TMPZIP" python3 -I - <<'PY'
import os, struct, sys
png = open(os.environ["PNG_IN"], "rb").read()
assert png[:8] == b"\x89PNG\r\n\x1a\n", "kein gueltiges PNG"
i, found = 8, False
while i + 8 <= len(png):
    ln = struct.unpack(">I", png[i:i+4])[0]
    ctype = png[i+4:i+8]
    if ctype == b"flGn":
        open(os.environ["TMPZIP"], "wb").write(png[i+8:i+8+ln])
        print("    extrahiert:", ln, "bytes")
        found = True
        break
    i += 12 + ln
if not found:
    sys.exit("Fehler: kein 'flGn'-Chunk im PNG gefunden.")
PY

echo "[2/2] ZIP entpacken nach '$DEST' ..."
unzip -o -q -P "$PASS" "$TMPZIP" -d "$DEST"

echo "Fertig. Inhalt in: $DEST"
