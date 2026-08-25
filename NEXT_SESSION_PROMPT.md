Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: retry the blocked scoring-play live verification — whether ESPN
football scoreboard payloads carry `competitions[].details` while a game is
in progress — strictly observationally, during real football minutes. If the
current time is outside live football minutes, or the owner directs a
different slice from the `competition.md` decision list, do that instead; do
not infer direction.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md` (see
the "Latest handoff — 2026-08-25 notification games binding-loop fix" and the
blocked 2026-08-24 scoring-play verification), and `competition.md`.
`docs/upstream-contract.md` is intentionally absent in this checkout; inspect
installed Omarchy/Quickshell sources directly for any host-boundary claim and
record material deviations in `roadmap.md`. Inspect `git status`, the current
branch, and recent commits. Preserve unrelated user changes, including the
absence of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-25, after the binding-loop fix):

- `main` is clean. 223 deterministic tests pass; plugin validation,
  real-import-path `qmllint`, summon-helper tests, and `git diff --check`
  pass. One healthy Quickshell instance runs the linked checkout with zero
  binding-loop warnings in its fresh log; the recorded
  `NotificationService` `games` loop is fixed by a settings identity guard in
  `SettingsStore.writeState`, pinned by `fixtures/settings-boundary/`
  `binding-loop.json` coverage.
- Persisted owner state: six leagues enabled (nhl restored), six favorites
  (eng.1:362 restored), notification preferences unchanged. Do not alter
  favorites or enabled leagues during verification.

Bounded outcome (live-minutes window only):

One read-only observational unit: fetch the two documented football
scoreboards (`https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard`
and `.../college-football/scoreboard`) while at least one game is `in`
progress, and record whether `competitions[].details` exists, with a bounded
shape summary (field names only, no bulk payload in the repo). If `details`
exists with a stable shape, record the evidence and stop — any adapter work
is a separate owner-directed unit. If `details` is absent even live, record
that this closes the scoring-plays idea under the current single-endpoint
boundary. If no live game exists during the session, record the retry window
missed and stop without changes; CFB week 0 runs from Sat Aug 29, NFL week 1
from Thu Sep 10 (2026 season).

Required checks (rerun after any change; for the pure observational outcome,
rerun to record the unchanged baseline):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- If (and only if) repository source changes: on actual Omarchy use
  `omarchy-restart-shell` (rescan alone does not reload the linked
  singleton/fetch service), confirm one Quickshell instance and
  `shell ping` → `ok`, exercise the changed behavior, and inspect the fresh
  log for no new Sportray error, exception, or binding-loop warning. Do not
  toggle the owner's enabled leagues or favorites for testing.

Known risks and stop conditions: ESPN is an undocumented API; even a live
game may never populate `details` on the scoreboard endpoint. Keep the
verification observational — no new endpoint, provider adapter, or fetch
path. Gated owner-directed alternatives: a second verified provider adapter
for live multi-provider fallback (P1-4 remainder) requires the owner's
explicit terms/region/reliability review first. Stop before packaging,
tagging, pushing, releasing, or Marketplace work. Do not weaken acceptance
gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and create
one atomic Conventional Commit-style commit only when all applicable gates
pass (a blocked observational unit records evidence and creates no success
commit). Request subagents only for independent read-only reconnaissance; the
main agent owns edits, validation, handoff, and commit.
