Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: add one fixture-driven optional rich-detail projection to the
provider-neutral model, without restoring the local game-details route or
adding a new endpoint.

Before editing, read `AGENTS.md`, `README.md`, `docs/upstream-contract.md`,
`roadmap.md`, `competition.md`, and the latest handoff in this file.
`docs/upstream-contract.md` is intentionally absent in this checkout; inspect
the installed Omarchy/Quickshell sources directly and record any material
boundary deviation. Inspect `git status`, the current branch, and recent
commits. Preserve the unrelated deletion of `MARKETPLACE_SUBMISSION.md`; do
not restore or stage it.

Verified current state:

- Sportray supports eight leagues, canonical favorites, Following and stable
  league destinations, bounded date/cache/polling behavior, settings,
  accessibility, source attribution, notifications, and NHL/ESPN standings.
- The local game-details route was intentionally removed in the latest unit:
  whole-row activation now uses the existing guarded ESPN/NHL.com source
  page, and `Panel.qml` no longer mounts `GameDetailView` or owns detail state.
  The retained `model/GameDetailModel.js` and `components/GameDetailView.qml`
  are future groundwork, not a current product route.
- The current model projects normalized games only and does not fetch a second
  event endpoint. Existing ESPN fixtures contain normalized fields that may
  support one bounded optional section. Do not expose canonical IDs as user
  facing content.
- Provider parsing stays in `providers/`; QML consumes bounded projections.
  Preserve the no-account/no-backend/no-daemon, response-size, item-count,
  safe-URL, and canonical favorite boundaries.
- The latest unit passed 185 deterministic JavaScript tests, plugin
  validation, real-import-path QML lint, diff check, and an actual Omarchy
  rescan/summon/log check. Child-route IPC and a reliable desktop pointer
  injector remain unavailable; do not claim a manual UI interaction without
  direct evidence.

Bounded outcome:

Inspect `model/GameDetailModel.js`, normalized ESPN game payloads,
`fixtures/espn/raw/game-detail.json`, and the existing model tests. Add exactly
one small optional provider-neutral detail section or projection field that is
materially richer than the scoreboard card but already present in normalized
data. Keep the local route removed and do not modify `Panel.qml` or re-expose
`GameDetailView`. Add fixture-driven coverage for present, missing, malformed,
and bounded values. Keep source actions and row routing unchanged.

Required checks and stop condition:

- Run `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, real-
  import-path `qmllint` over any changed QML, and `git diff --check`.
- If QML changes despite the bounded outcome, rescan the linked plugin on
  actual Omarchy, exercise behavior as far as the host allows, and inspect
  Quickshell logs. Do not report actual-runtime success without evidence.
- Stop before restoring the local detail route, adding a second endpoint,
  provider-specific UI, provider fallback, NHL standings changes,
  pregame/close alerts, broader discovery, calendar redesign, specialist
  sports, packaging, tagging, pushing, releases, or Marketplace work.

At completion, update `roadmap.md` with evidence, decisions, and a dated
handoff; replace this file with the next self-contained single-unit prompt;
and create one atomic Conventional Commit-style commit only after the gates
pass. Use subagents only for independent read-only fixture or upstream
reconnaissance that materially improves confidence; the main agent owns all
edits, integration, validation, handoff, and commit.
