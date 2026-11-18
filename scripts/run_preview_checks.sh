#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PREVIEW_PORT:-3100}"
BASE_URL="http://127.0.0.1:${PORT}"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"

bin/rails server -e test -p "$PORT" > tmp/preview-server.log 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 60); do
  if curl -fsS "${BASE_URL}/up" >/dev/null; then
    break
  fi
  sleep 1
done

if ! curl -fsS "${BASE_URL}/up" >/dev/null; then
  echo "Preview server failed to start. See tmp/preview-server.log"
  exit 1
fi

PREVIEW_BASE_URL="$BASE_URL" node scripts/check_a11y.mjs
if [[ "${UPDATE_VISUAL_BASELINES:-false}" == "true" ]]; then
  PREVIEW_BASE_URL="$BASE_URL" node scripts/check_visual_regression.mjs --update-baseline
else
  PREVIEW_BASE_URL="$BASE_URL" node scripts/check_visual_regression.mjs
fi
