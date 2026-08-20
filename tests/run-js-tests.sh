#!/usr/bin/env bash
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ -n "${NODE_BIN:-}" ]; then
  exec "$NODE_BIN" "$ROOT_DIR/tests/run-js-tests.js"
fi

if command -v node >/dev/null 2>&1 && node --version >/dev/null 2>&1; then
  exec node "$ROOT_DIR/tests/run-js-tests.js"
fi

if command -v mise >/dev/null 2>&1; then
  exec mise exec node@26.7.0 -- node "$ROOT_DIR/tests/run-js-tests.js"
fi

echo "No working Node.js binary found; set NODE_BIN explicitly." >&2
exit 1
