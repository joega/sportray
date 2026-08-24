#!/usr/bin/env bash

set -u

readonly REPOSITORY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly HELPER="$REPOSITORY_DIR/scripts/summon-sportray-after-rescan.sh"
readonly TEST_DIR="$(mktemp -d)"
readonly FAKE_BIN="$TEST_DIR/bin"
readonly LOG_PATH="$TEST_DIR/calls.log"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

fail() {
  echo "summon helper test failed: $1" >&2
  exit 1
}

mkdir -p "$FAKE_BIN"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\\n" "$*" >> "$CALL_LOG"' \
  'attempt="$(wc -l < "$CALL_LOG")"' \
  'if (( attempt >= SUCCESS_AFTER )); then echo ok; else echo unknown; fi' \
  > "$FAKE_BIN/omarchy-shell"
chmod +x "$FAKE_BIN/omarchy-shell"

rm -f "$LOG_PATH"
if ! output="$(CALL_LOG="$LOG_PATH" SUCCESS_AFTER=3 PATH="$FAKE_BIN:$PATH" "$HELPER")"; then
  fail "successful retry sequence returned nonzero"
fi
[[ "$output" == "ok" ]] || fail "successful sequence did not report ok"
[[ "$(wc -l < "$LOG_PATH")" -eq 3 ]] || fail "success was not detected on the third attempt"
while IFS= read -r call; do
  [[ "$call" == "shell summon io.github.joega.sportray {}" ]] \
    || fail "unexpected summon arguments: $call"
done < "$LOG_PATH"

rm -f "$LOG_PATH"
if failure_output="$(CALL_LOG="$LOG_PATH" SUCCESS_AFTER=99 PATH="$FAKE_BIN:$PATH" "$HELPER" 2>&1)"; then
  fail "bounded failure sequence returned zero"
fi
[[ "$failure_output" == "sportray summon failed after 5 attempts" ]] \
  || fail "failure was not concise: $failure_output"
[[ "$(wc -l < "$LOG_PATH")" -eq 5 ]] || fail "failure exceeded the five-attempt bound"

echo "summon helper tests passed"
