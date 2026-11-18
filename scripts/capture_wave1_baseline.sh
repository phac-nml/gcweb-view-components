#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/fixtures/wave-1/manifest.json"
pages_dir="$repo_root/fixtures/wave-1/pages"
shots_dir="$repo_root/fixtures/wave-1/screenshots"
with_screenshots=false

if [[ "${1:-}" == "--with-screenshots" ]]; then
  with_screenshots=true
fi

mkdir -p "$pages_dir" "$shots_dir"

echo "Capturing HTML fixtures..."
jq -r '.templates[] | [.url, .html_path] | @tsv' "$manifest" | while IFS=$'\t' read -r url html_path; do
  target="$repo_root/$html_path"
  curl -fsSL "$url" -o "$target"
  echo "  saved: $html_path"
done

if $with_screenshots; then
  echo "Capturing screenshots (Playwright CLI via npx)..."
  jq -r '.templates[] | [.url, .screenshot_path] | @tsv' "$manifest" | while IFS=$'\t' read -r url shot_path; do
    target="$repo_root/$shot_path"
    npx -y playwright@1.51.1 screenshot --device="Desktop Chrome" "$url" "$target" >/dev/null
    echo "  saved: $shot_path"
  done
fi

captured_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp_manifest="$(mktemp)"
jq --arg ts "$captured_at" '.captured_at_utc = $ts' "$manifest" > "$tmp_manifest"
mv "$tmp_manifest" "$manifest"

echo "Done. captured_at_utc=$captured_at"
