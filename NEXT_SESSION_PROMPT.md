Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: during the live-football window (CFB week 0 from Sat Aug 29; NFL week 1
from Thu Sep 10, 2026), perform one combined observational verification of
the remaining unverified ESPN scoreboard fields — `competitions[].details`
(scoring plays), `competitions[].weather`, and `competitions[].leaders` —
while at least one football game is in progress. If the current time is
outside live football minutes, or the owner directs a different slice from
the `competition.md` decision list, do that instead; do not infer direction.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md` (see
the "Latest handoff — 2026-08-25 game-detail bounds and ID removal" and the
blocked 2026-08-24 scoring-play verification), and `competition.md`.
`docs/upstream-contract.md` is intentionally absent in this checkout; inspect
installed Omarchy/Quickshell sources directly for any host-boundary claim and
record material deviations in `roadmap.md`. Inspect `git status`, the current
branch, and recent commits. Preserve unrelated user changes, including the
absence of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-25, after commits `a905e6a`, `1414304`, and
the game-detail bounds fix):

- `main` is clean. 225 deterministic tests pass; plugin validation,
  real-import-path `qmllint`, summon-helper tests, and `git diff --check`
  pass. One healthy Quickshell instance runs the linked checkout with zero
  binding-loop warnings.
- The `NotificationService` `games` binding loop is fixed (settings identity
  guard in `SettingsStore.writeState`); attributed betting odds project onto
  scheduled score cards and the game-details drill-down from the already
  fetched snapshot; the detail view now hides all internal game IDs and
  scrolls within the bounded panel height.
- Owner configuration: six leagues enabled, six favorites, notification
  preferences unchanged. Do not alter favorites or enabled leagues during
  verification.

Bounded outcome (live-minutes window only):

One read-only observational unit: fetch the two documented football
scoreboards (`https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard`
and `.../college-football/scoreboard`) while at least one game is `in`
progress and record, field names and bounded shape summaries only:

- whether `competitions[].details` exists and its entry shape (scoring
  plays);
- whether `competitions[].weather` exists and its shape (it was absent from
  every payload inspected 2026-08-25; it historically appears near kickoff);
- whether `competitions[].leaders` groups carry any athlete entries (all
  inspected groups on 2026-08-25 were empty).

If a field exists with a stable shape, record the evidence and stop — any
adapter work is a separate owner-directed unit. If a field is absent even
live, record that outcome; absent `details` would close the scoring-plays
idea under the current single-endpoint boundary. If no live game exists
during the session, record the missed window and stop without changes.

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

Known risks and stop conditions: ESPN is an undocumented API; even live
games may never populate `details` on the scoreboard endpoint. Keep the
verification observational — no new endpoint, provider adapter, or fetch
path, and no raw payload bulk in the repository. Gated owner-directed
alternative: a second verified provider adapter for live multi-provider
fallback (P1-4 remainder) requires the owner's explicit terms/region/
reliability review first. Stop before packaging, tagging, pushing,
releasing, or Marketplace work. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and create
one atomic Conventional Commit-style commit only when all applicable gates
pass (a blocked observational unit records evidence and creates no success
commit). Request subagents only for independent read-only reconnaissance; the
main agent owns edits, validation, handoff, and commit.
