Work in `/home/joeg/Projects/sportray` on the next bounded product unit:
design and implement the first generic game-detail data/model slice that
follows the completed standings/league-view unit.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify any
Omarchy/Quickshell boundary against installed Omarchy and Quickshell sources.
Inspect `git status`, the current branch, recent commits, the standings handoff,
provider adapters, normalized game model, fixtures, and tests. Preserve
unrelated changes.

Verified current state:

- The standings slice is complete: `StandingsModel` and `StandingsRows` provide
  provider-neutral grouped rows, nullable metrics, deterministic ordering,
  empty/error shaping, and canonical team IDs for existing favorite actions.
- `EspnProvider` has one fixture-backed standings parser path and
  `StandingsFetch.qml` is a single on-demand fetch boundary. Existing ESPN
  league destinations have a small grouped standings route; NHL remains
  scores-only because no standings adapter has been verified.
- The scores route, normalized game model, date/cache boundaries, settings,
  accessibility, privacy, and notification contracts remain in place. Provider
  parsing stays outside QML.
- Fixture tests cover standings ordering, missing values, empty/malformed
  payloads, and favorite routing. The JS suite, actual Omarchy plugin
  validation, real-import-path QML lint, diff check, plugin rescan, fresh log
  inspection, and live empty-state route exercise passed for the completed
  unit. The live ESPN offseason payload was sparse/empty, so populated standings
  remain fixture-verified.
- `docs/upstream-contract.md` is intentionally absent; the completed unit used
  installed Omarchy/Quickshell sources. Marketplace issue #873 and all public
  publication work remain owner-controlled and out of scope.

Bounded outcome:

Implement only a generic provider-neutral game-detail model and one
fixture-backed provider parser path, using the existing normalized game shape
as the source boundary. Cover the smallest useful detail fields (identity,
participants, status, timing, score, venue/source metadata) with explicit
nulls for omissions and bounded malformed-input errors. Add fixture-driven
ordering/normalization/missing-field/malformed-input tests. Do not add a new
league, provider fallback, alerts, bar mode, packaging, or a broad QML redesign.
If provider payloads cannot support a reliable shape, document the adapter
contract and stop after pure model/fixture work.

Required checks and stop condition:

- Read and inspect current upstream sources before changing any QML or
  Quickshell boundary.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the
  real-import-path `qmllint` command over every QML file, and `git diff --check`.
- If QML changes, rescan the linked plugin on actual Omarchy, inspect the fresh
  Quickshell log, and manually exercise the changed route. Do not report an
  Omarchy check as passing unless it actually ran there.
- Stop before game-detail drill-down UI if it would expand this slice, and
  before bar modes, live rotation, provider chains, alerts, new leagues, niche
  adapters, packaging, tagging, pushing, releases, or Marketplace actions.
- At completion, update `roadmap.md` with status, evidence, decisions, risks,
  and a dated handoff; replace this file with the next single bounded prompt;
  and create one atomic Conventional Commit-style commit only after every gate
  passes. Use subagents only for independent read-only work that materially
  improves confidence.
