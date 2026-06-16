#!/usr/bin/env bash
# Copy tree-sitter WASM, queries, and web runtime to web/public/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$ROOT/web"
TS_DIR="$ROOT/tree-sitter"
PUBLIC_DIR="$WEB_DIR/public"
WTS_MODULE="$WEB_DIR/node_modules/web-tree-sitter"

# Copy grammar WASM if it exists
if [ -f "$TS_DIR/tree-sitter-CoCo.wasm" ]; then
  echo "=== Copying tree-sitter CoCo WASM ==="
  cp "$TS_DIR/tree-sitter-CoCo.wasm" "$PUBLIC_DIR/tree-sitter-coco.wasm"
else
  echo "=== Skipping tree-sitter WASM (not built) ==="
fi

# Copy highlight queries
if [ -f "$TS_DIR/queries/highlights.scm" ]; then
  echo "=== Copying highlight queries ==="
  cp "$TS_DIR/queries/highlights.scm" "$PUBLIC_DIR/highlights.scm"
else
  echo "=== Warning: highlights.scm not found ==="
fi

# Copy web-tree-sitter runtime files
echo "=== Copying web-tree-sitter runtime ==="
if [ -d "$WTS_MODULE" ]; then
  cp "$WTS_MODULE/web-tree-sitter.js" "$PUBLIC_DIR/" 2>/dev/null || true
  cp "$WTS_MODULE/web-tree-sitter.wasm" "$PUBLIC_DIR/" 2>/dev/null || true
else
  echo "=== Warning: web-tree-sitter not found in node_modules ==="
fi

echo "=== Done ==="
