Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: add one opt-in, favorite-only pregame reminder policy through the
existing notification pipeline, without adding a new endpoint or daemon.

Before editing, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, `competition.md`, and the latest
handoff in this file. `docs/upstream-contract.md` is intentionally absent in
this checkout; inspect installed Omarchy/Quickshell sources directly and
record any material boundary deviation. Inspect `git status`, the current
branch, and recent commits. Preserve the unrelated deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- Sportray supports eight leagues, canonical favorites, Following and stable
  league destinations, bounded date/cache/polling behavior, settings,
  accessibility, source attribution, notifications, and NHL/ESPN standings.
- The local game-details route is removed. Whole-row activation uses the
  existing guarded ESPN/NHL.com source page. `Panel.qml` does not mount
  `GameDetailView` or own detail state; the retained detail model/view are
  future groundwork.
- `model/GameDetailModel.js` now has one optional provider-neutral `outcome`
  projection from complete bounded final scores. It is not mounted in QML and
  must remain unchanged in this unit.
- The current notification path is favorite-only, first-fetch silent,
  deduplicated, bounded, and routed through the existing
  `/usr/bin/omarchy-notification-send` helper. Normalized games already carry
  `startTime`; do not fetch per-game data.
- The latest unit passed 186 deterministic JavaScript tests, plugin
  validation, full real-import-path QML lint, diff check, and an actual
  Omarchy rescan/summon/log health check. Child-route IPC and a reliable
  desktop pointer injector remain unavailable; do not claim a manual UI
  interaction without direct evidence.

Bounded outcome:

Implement one pure, fixture-driven pregame reminder admission/policy using
existing normalized favorite games and `startTime`, then connect only the
minimum existing notification call path required by that policy. The policy
must be opt-in, favorite-only, date-scoped, bounded in lead time and text,
silent for missing/malformed/stale timestamps, and deduplicated through the
existing transition state. Preserve existing start, score-change, and final
notification behavior. Do not expose canonical IDs in notification text.

Required coverage and checks:

- Add fixtures/tests for an eligible upcoming favorite, disabled preference,
  non-favorite, missing/malformed timestamp, out-of-window timestamp, bounded
  notification text, and duplicate suppression.
- Run `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` over any changed QML, and `git diff --check`.
- If QML changes, rescan the linked plugin on actual Omarchy, exercise only
  what the host allows, and inspect Quickshell logs. Do not report runtime UI
  success without evidence.

Stop before close-game alerts, a second endpoint, provider-specific UI,
provider fallback, broader discovery, calendar redesign, specialist sports,
packaging, tagging, pushing, releases, or Marketplace work. At completion,
update `roadmap.md` with evidence, decisions, and a dated handoff; replace
this file with the next self-contained single-unit prompt; and create one
atomic Conventional Commit-style commit only after all gates pass. Use
subagents only for independent read-only notification or upstream
reconnaissance that materially improves confidence; the main agent owns all
edits, integration, validation, handoff, and commit.
