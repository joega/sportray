Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: add one optional rich game-detail section using an already normalized
ESPN fixture, without adding a new endpoint.

Before editing, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, `competition.md`, and the latest
handoff in this file. `docs/upstream-contract.md` is intentionally absent in
this checkout; inspect the installed Omarchy/Quickshell sources directly and
record any material boundary deviation. Inspect `git status`, branch and
recent commits, then review `model/GameDetailModel.js`, normalized ESPN game
payloads, the existing local detail route, fixtures, and tests. Preserve the
unrelated deletion of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- Sportray supports eight leagues, canonical favorites, Following and stable
  league destinations, bounded date/cache/polling behavior, settings,
  accessibility, source attribution, notifications, and a local provider-
  neutral game-detail route.
- ESPN and NHL standings now use the shared normalized standings model and
  presentation. NHL standings are sourced from the verified
  `api-web.nhle.com/v1/standings/now` shape, grouped by Eastern/Western
  conference, ordered by conference sequence, and mapped through the bounded
  current NHL team catalog. Do not modify that unit here.
- The existing detail model is a sparse projection of an already loaded game;
  it has no second endpoint. ESPN provider fixtures already contain the
  normalized event data needed for one optional section.
- Provider parsing stays in `providers/`; QML consumes bounded projections.
  Preserve the no-account/no-backend/no-daemon, response-size, item-count,
  safe-URL, and canonical favorite boundaries.
- Actual Omarchy validation, real-import-path lint, and JS tests passed for the
  NHL unit. The bar-widget can be summoned, but child route IPC and a reliable
  desktop pointer injector were unavailable for a final visual standings
  toggle; do not turn that limitation into an unsupported runtime claim.

Bounded outcome:

Inspect the existing normalized ESPN detail fixture and add exactly one small,
optional provider-neutral detail section (for example a bounded venue or
status/timing context already present in the normalized game) to the existing
local detail projection and route. Keep all existing base fields and source
actions unchanged. Add fixture-driven parser/model/projection coverage for
present, missing, malformed, and bounded values. Do not fetch another endpoint,
add provider fallback, or begin sport-specific detail.

Required checks and stop condition:

- Run `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `qmllint` over any changed QML, and `git diff --check`.
- If QML changes, rescan the linked plugin on actual Omarchy, exercise the
  existing detail route as far as the host allows, and inspect Quickshell logs.
  Do not claim actual-runtime success without actual Omarchy evidence.
- Stop before richer multi-section detail, new endpoints, NHL standings
  changes, pregame/close alerts, provider fallback chains, broader discovery,
  calendar redesign, specialist sports, packaging, tagging, pushing, releases,
  or Marketplace work.

At completion, update `roadmap.md` with evidence, decisions, and a dated
handoff; replace this file with the next self-contained single-unit prompt;
and create one atomic Conventional Commit-style commit only after the gates
pass. Use subagents only for independent read-only fixture or upstream
reconnaissance that materially improves confidence; the main agent owns all
edits, integration, validation, handoff, and commit.
