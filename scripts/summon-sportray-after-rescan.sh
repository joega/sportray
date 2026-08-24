#!/usr/bin/env bash

set -u

readonly PLUGIN_ID="io.github.joega.sportray"
readonly MAX_ATTEMPTS=5
readonly RETRY_DELAY_SECONDS="0.25"

if ! command -v omarchy-shell >/dev/null 2>&1; then
  echo "sportray summon failed: omarchy-shell not found" >&2
  exit 1
fi

for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
  response="$(omarchy-shell shell summon "$PLUGIN_ID" '{}' 2>/dev/null || true)"
  if [[ "$response" == "ok" ]]; then
    printf '%s\n' "$response"
    exit 0
  fi

  if (( attempt < MAX_ATTEMPTS )); then
    sleep "$RETRY_DELAY_SECONDS"
  fi
done

echo "sportray summon failed after $MAX_ATTEMPTS attempts" >&2
exit 1
