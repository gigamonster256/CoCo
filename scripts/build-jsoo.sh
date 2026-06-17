#!/usr/bin/env bash
# Build CoCo js_of_ocaml output and copy to web/lib/coco/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$ROOT/web"
DEST_DIR="$WEB_DIR/public/lib/coco"

echo "=== Building js_of_ocaml (OCaml -> JS) ==="
cd "$ROOT"
dune build ./jsoo/coco_js.bc.js

echo "=== Copying output to $DEST_DIR ==="
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"
cp _build/default/jsoo/coco_js.bc.js "$DEST_DIR/coco_js.js"

echo "=== Done ==="
