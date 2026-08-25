Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit. There are two candidate units; follow this decision rule exactly:

1. If the owner has answered the three provider-review questions recorded in
   the "Second-provider candidate reconnaissance — 2026-08-25" roadmap
   handoff (MLB StatsAPI terms acceptance, first second-candidate league,
   and the explicit id-translation requirement), implement the first
   second-candidate adapter as one bounded vertical slice.
2. Otherwise, during live-football minutes (CFB week 0 from Sat Aug 29; NFL
   week 1 from Thu Sep 10, 2026), perform the standing read-only
   observational verification of `competitions[].details` (scoring plays),
   `competitions[].weather`, and `competitions[].leaders` while at least one
   football game is in progress.
3. Outside live-football minutes with no owner answers, do not infer
   direction: recheck for owner direction, and if absent, record the
   unchanged blocker state and stop without changes.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md` (see
the "Second-provider candidate reconnaissance — 2026-08-25" handoff and the
blocked 2026-08-24 scoring-play verification), and `competition.md`.
`docs/upstream-contract.md` is intentionally absent in this checkout; inspect
installed Omarchy/Quickshell sources directly for any host-boundary claim and
record material deviations in `roadmap.md`. Inspect `git status`, the current
branch, and recent commits. Preserve unrelated user changes, including the
absence of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-25, after the viewport-fraction detail-height
unit and the provider reconnaissance unit):

- `main` is clean. 226 deterministic tests pass; plugin validation,
  real-import-path `qmllint`, summon-helper tests, and `git diff --check`
  pass. One healthy Quickshell instance runs the linked checkout with zero
  binding-loop warnings.
- Reconnaissance findings for the adapter unit: MLB StatsAPI
  (`https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=YYYY-MM-DD&hydrate=team,linescore`)
  is key-free, CDN-cached (`max-age=20`, `stale-if-error=86400`), and carries
  `dates[].games[]` with `gamePk`, UTC `gameDate`,
  `status.{abstractGameState, detailedState}`, `teams.away/home.{team.{id,
  name, abbreviation}, score}`, `venue.name`, optional `linescore`. ESPN's
  NHL scoreboard is the same already-verified ESPN shape. Both candidates
  need an explicit team-id translation (MLB StatsAPI Tigers id 116 vs ESPN 3;
  ESPN NHL BOS 1 vs NHL.com 6, UTA 129764 vs 68; tri-codes `TB`/`TBL`,
  `SJ`/`SJS`, `LA`/`LAK` differ) so canonical
  `<league>:<providerTeamId>` favorite identity survives provider switches.
  MLB terms ("individual, non-commercial, non-bulk use" per
  `gdx.mlb.com/components/copyright.txt`) require owner acceptance first.
- Owner configuration: six leagues enabled, six favorites, notification
  preferences unchanged. Do not alter favorites or enabled leagues during
  verification.

Bounded outcome for path 1 (adapter unit, owner answers given): one vertical
slice adding the second candidate for the owner-chosen league only — provider
parsing in `providers/` (new `MlbStatsProvider.js` for MLB, or the ESPN NHL
scoreboard route through `EspnProvider` with id translation), the explicit
id-translation table, fixture coverage including live-state variants and
empty/offseason slates, `LeagueCatalog.providerChain()` gaining its second
candidate, and bounded polling/response admission unchanged. Do not touch
settings schema, QML views, notifications, or other leagues.

Bounded outcome for path 2 (observational, live minutes only): fetch the two
documented football scoreboards
(`https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard` and
`.../college-football/scoreboard`) while at least one game is `in` progress
and record field names and bounded shape summaries only for `details`,
`weather`, and `leaders`. If a field exists with a stable shape, record the
evidence and stop — adapter work is a separate owner-directed unit. If a
field is absent even live, record that outcome; absent `details` closes the
scoring-plays idea under the current single-endpoint boundary. If no live
game exists during the session, record the missed window and stop.

Required checks (rerun after any change; for a pure observational outcome,
rerun to record the unchanged baseline):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- If (and only if) repository QML/service source changes: on actual Omarchy
  use `omarchy-restart-shell` (rescan alone does not reload the linked
  singleton/fetch service), confirm one Quickshell instance and
  `shell ping` → `ok`, exercise the changed behavior, and inspect the fresh
  log for no new Sportray error, exception, or binding-loop warning. Do not
  toggle the owner's enabled leagues or favorites for testing.

Known risks and stop conditions: ESPN and MLB StatsAPI are undocumented
APIs; shapes may change without notice. The MLB terms determination is
owner-owned — do not implement the MLB adapter without the owner's explicit
terms acceptance. Keep any verification observational — no new endpoint,
provider adapter, or fetch path beyond the owner-approved slice, and no raw
payload bulk in the repository. Stop before packaging, tagging, pushing,
releasing, or Marketplace work. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and create
one atomic Conventional Commit-style commit only when all applicable gates
pass (a blocked observational unit records evidence and creates no success
commit). Request subagents only for independent read-only reconnaissance; the
main agent owns edits, validation, handoff, and commit.
