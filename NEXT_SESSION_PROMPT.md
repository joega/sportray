Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: add one independently configurable, favorite-only close-game alert
through the existing normalized-game notification pipeline.

Before editing, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, `competition.md`, and the latest
handoff in this file. `docs/upstream-contract.md` is intentionally absent in
this checkout; inspect installed Omarchy/Quickshell sources directly and
record any material boundary deviation. Inspect `git status`, the current
branch, and recent commits. Preserve unrelated user changes, including any
deletion of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- Sportray supports eight leagues, canonical favorites, Following and stable
  league destinations, bounded date/cache/polling behavior, settings,
  accessibility, source attribution, notifications, and NHL/ESPN standings.
- The local game-details route is removed. Whole-row activation uses the
  existing guarded ESPN/NHL.com source page. `Panel.qml` does not mount
  `GameDetailView` or own detail state; the retained detail model/view are
  future groundwork.
- `model/GameDetailModel.js` has one optional provider-neutral `outcome`
  projection from complete bounded final scores. It is not mounted in QML and
  must remain unchanged in this unit.
- `model/PregameReminderPolicy.js` and the `pregameReminder` schema-1 setting
  are complete. The opt-in policy is favorite-only, local-today scoped,
  scheduled-status-only, silent for invalid/stale timestamps, bounded to the
  next 30 minutes, first-fetch silent, and deduplicated by the existing
  persisted transition state using `gameId:pregame` fingerprints.
- The existing notification pipeline is favorite-only, first-fetch silent,
  bounded, restart-safe, and routed through
  `/usr/bin/omarchy-notification-send`. Existing start, score-change, final,
  test-preview, and pregame behavior must remain intact. Normalized games
  already carry scores/status/startTime; do not fetch per-game data.
- The latest completed unit passed 188 deterministic JavaScript tests,
  plugin validation, full real-import-path QML lint, diff check, and an actual
  Omarchy rescan/summon/hide/log health check. Child-route IPC and a reliable
  desktop pointer injector remain unavailable; do not claim manual UI success
  without direct evidence.

Bounded outcome:

Implement one pure, fixture-driven close-game admission/projection using
existing normalized live-game scores/status and then connect only the minimum
existing notification call path required by that policy. The policy must be
opt-in, favorite-only, bounded to a clearly documented provider-neutral
condition, silent for missing/malformed/inapplicable score state, date-scoped,
bounded in text, and deduplicated through the existing transition state. Do
not expose canonical IDs in notification text. Keep the new alert independent
from game starts, score changes, finals, and pregame reminders.

Required coverage and checks:

- Add fixtures/tests for an eligible close game, disabled preference,
  non-favorite, non-live or missing-score state, out-of-threshold score state,
  bounded notification text, and duplicate suppression across state reload.
- Add one notification-settings toggle with a default-off schema-1 value only
  if needed to make the opt-in behavior user-controllable; preserve old
  schema-1 recovery and future-schema opacity.
- Run `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` over changed QML (and all QML if practical), and
  `git diff --check`.
- If QML changes, rescan the linked plugin on actual Omarchy, exercise only
  what the host allows, and inspect Quickshell logs. Do not report runtime UI
  success without evidence.

Stop before a second endpoint, provider-specific UI, provider fallback,
broader discovery, calendar redesign, specialist sports, packaging, tagging,
pushing, releases, or Marketplace work. At completion, update `roadmap.md`
with evidence, decisions, and a dated handoff; replace this file with the next
self-contained single-unit prompt; and create one atomic Conventional
Commit-style commit only after all gates pass. Use subagents only for
independent read-only notification or upstream reconnaissance that materially
improves confidence; the main agent owns all edits, integration, validation,
handoff, and commit.
