#!/usr/bin/env bash
# Build CoCo Melange output and copy to web/lib/coco/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$ROOT/web"
OUT_DIR="$ROOT/_build/default/output"
DEST_DIR="$WEB_DIR/lib/coco"

echo "=== Building Melange (OCaml -> JS) ==="
cd "$ROOT"
dune build @mel

echo "=== Copying output to $DEST_DIR/lib ==="
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR/lib"
cp "$OUT_DIR/melange-lib"/*.js "$DEST_DIR/lib/"
cp -r "$OUT_DIR/node_modules" "$DEST_DIR/"

echo "=== Done ==="
