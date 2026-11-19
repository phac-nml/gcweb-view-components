#!/usr/bin/env bash
# Start the demo app in test mode and run the preview quality checks:
#   1. GCWeb parity (computed styles vs test/gcweb_reference)
#   2. Accessibility (axe, WCAG 2.1 AA)
#   3. Visual regression (per-platform screenshots)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PREVIEW_PORT:-3100}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG="$ROOT_DIR/demo/tmp/preview-server.log"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Refuse to run against some other server (e.g. a running bin/dev) on the port.
if curl -fsS "${BASE_URL}/up" >/dev/null 2>&1; then
  echo "Port ${PORT} is already in use (is bin/dev running?). Stop it or set PREVIEW_PORT." >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/demo/tmp"
(cd "$ROOT_DIR/demo" && bin/vite build --mode test >/dev/null && exec bin/rails server -e test -p "$PORT") > "$LOG" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 60); do
  curl -fsS "${BASE_URL}/up" >/dev/null 2>&1 && break
  sleep 1
done

if ! curl -fsS "${BASE_URL}/up" >/dev/null 2>&1; then
  echo "Preview server failed to start. See demo/tmp/preview-server.log"
  exit 1
fi

cd "$ROOT_DIR"
export PREVIEW_BASE_URL="$BASE_URL"

node scripts/check_gcweb_parity.mjs
node scripts/check_a11y.mjs
if [[ "${UPDATE_VISUAL_BASELINES:-false}" == "true" ]]; then
  node scripts/check_visual_regression.mjs --update-baseline
else
  node scripts/check_visual_regression.mjs
fi
