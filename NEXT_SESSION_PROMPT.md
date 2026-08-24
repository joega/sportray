Work in `/home/joeg/Projects/sportray` on the next bounded product unit:
implement the smallest existing-route game-detail drill-down UI backed by the
completed generic game-detail data/model slice.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify any
Omarchy/Quickshell boundary against installed Omarchy and Quickshell sources.
Inspect `git status`, the current branch, recent commits, the game-detail
handoff, `model/GameDetailModel.js`, `model/GameModel.js`, the ESPN adapter,
fixtures, tests, and the existing Panel/GameRow route. Preserve unrelated
changes.

Verified current state:

- `GameDetailModel` projects an already normalized game into fixed
  provider-neutral identity, away/home participants, nullable scores, status,
  timing, venue, source metadata, and bounded error fields.
- `EspnProvider.parseGameDetailResponse` reuses the existing verified ESPN
  scoreboard normalization path and maps one fixture-backed payload into
  deterministically ordered detail records. No detail QML consumer exists yet.
- Detail fixtures and the JavaScript suite cover ordering, participant and
  status normalization, omitted-field nulls, malformed siblings, raw-payload
  exclusion, and the 256-record bound. The suite currently passes 165 tests.
- The existing scores route and source-link actions remain unchanged. NHL has
  no verified detail adapter, and the current detail projection does not imply
  box-score or play-by-play data. Provider parsing must remain outside QML.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 are the runtime boundary
  sources. The prior pure model/provider unit passed plugin validation, real
  import-path QML lint, and diff check; it made no QML changes.

Bounded outcome:

Add one small, keyboard-accessible detail presentation reachable from an
existing loaded game row or existing route. Reuse the normalized game and
`GameDetailModel` projection; render identity, both participants and scores,
status/timing, venue, and the existing safe provider source action. Preserve
explicit nulls as neutral placeholders and keep detail state local to the
current panel/view. Add fixture/source-driven tests for the route, action
reachability, sparse fields, and safe back/close behavior.

Do not add a new provider request or endpoint, box score, play-by-play, alerts,
bar mode, live rotation, provider fallback, new league, niche adapter,
packaging, tagging, pushing, release, or Marketplace work. Stop if making the
detail route reliable requires a provider contract beyond the current
scoreboard payload; document that contract risk in `roadmap.md` and leave the
pure model intact.

Required checks and stop condition:

- Read and inspect current installed Omarchy/Quickshell sources before changing
  any QML or Quickshell boundary.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` command over every QML file, and `git diff --check`.
- Because this unit changes QML, rescan the linked plugin on actual Omarchy,
  inspect the fresh Quickshell log, and manually exercise the detail route.
  Do not report an Omarchy check as passing unless it actually ran there.
- At completion, update `roadmap.md` with status, evidence, decisions, risks,
  and a dated handoff; replace this file with the next single bounded prompt;
  and create one atomic Conventional Commit-style commit only after every
  gate passes. Use subagents only for independent read-only work that
  materially improves confidence.
