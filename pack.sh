#!/usr/bin/env bash
#
# pack.sh – packt einen Ordner/Datei als passwortgeschütztes ZIP
#           und hängt es als privaten PNG-Chunk ("flGn") an ein Bild.
#           Das PNG bleibt ein gültiges, anzeigbares Bild.
#
# Benutzung:
#   ./pack.sh <quelle> <bild.png> <passwort> [ausgabe.png]
#
# Beispiel:
#   ./pack.sh FreeGuenther.app Bildschirmfoto.png 123456 Bild_mit_app.png
#
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Benutzung: $0 <quelle> <bild.png> <passwort> [ausgabe.png]" >&2
  exit 1
fi

SRC="$1"
PNG_IN="$2"
PASS="$3"
PNG_OUT="${4:-${PNG_IN%.png}_packed.png}"

[ -e "$SRC" ]    || { echo "Fehler: Quelle '$SRC' nicht gefunden." >&2; exit 1; }
[ -f "$PNG_IN" ] || { echo "Fehler: Bild '$PNG_IN' nicht gefunden." >&2; exit 1; }

TMPZIP="$(mktemp -t packzip).zip"
trap 'rm -f "$TMPZIP"' EXIT

echo "[1/2] ZIP erstellen (passwortgeschützt) ..."
# -r rekursiv, -e verschlüsselt, -P Passwort, -q leise
zip -r -q -e -P "$PASS" "$TMPZIP" "$SRC"

echo "[2/2] ZIP als PNG-Chunk anhängen ..."
PNG_IN="$PNG_IN" TMPZIP="$TMPZIP" PNG_OUT="$PNG_OUT" python3 -I - <<'PY'
import os, struct, zlib
png_in, payload_path, png_out = os.environ["PNG_IN"], os.environ["TMPZIP"], os.environ["PNG_OUT"]
png = open(png_in, "rb").read()
payload = open(payload_path, "rb").read()
assert png[:8] == b"\x89PNG\r\n\x1a\n", "kein gueltiges PNG"
iend = png.rfind(b"IEND") - 4
assert iend > 0, "IEND nicht gefunden"
ctype = b"flGn"  # ancillary + private -> Viewer ignorieren den Chunk
chunk = struct.pack(">I", len(payload)) + ctype + payload
chunk += struct.pack(">I", zlib.crc32(ctype + payload) & 0xffffffff)
open(png_out, "wb").write(png[:iend] + chunk + png[iend:])
print("    eingebettet:", len(payload), "bytes  ->", png_out)
PY

echo "Fertig: $PNG_OUT"
