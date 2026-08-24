Work in `/home/joeg/Projects/sportray` on the next bounded product unit:
design and implement the first generic standings/league-view slice identified
by the private competitive baseline.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify any
Omarchy/Quickshell boundary against installed Omarchy 4.0.0-1 and Quickshell
0.3.0 sources. Inspect `git status`, branch, recent commits, the current
league/presentation models, provider adapters, fixtures, and tests. Preserve
unrelated changes.

Verified current state:

- Sportray is an Omarchy Quattro bar widget with eight enabled/available
  leagues, favorites-first navigation, one stable destination per league, a
  five-day date carousel, bounded caches/polling, source links, settings,
  accessibility actions, and favorite-only start/score/final notifications.
- The live catalog now contains close generalist peers, especially
  `meirdick.scores`, plus `sportsbar`, `omatchday`, `omasoccer`, and focused
  MLB/F1/esports/VCT widgets. Their differentiating baseline is standings,
  useful league pages on empty game days, rich game detail, live bar rotation,
  provider fallback, and deeper opt-in alerts.
- The current roadmap explicitly prioritizes standings and league views before
  game detail, bar modes, provider chains, or niche sport adapters.
- Provider parsing must remain outside QML. The current normalized game model,
  date/cache boundaries, future-schema handling, settings permissions, and
  no-account/no-daemon privacy contract must remain intact.
- The public `origin/main` tree does not contain the private planning or
  Marketplace review files. Do not add them to public product files or push
  anything during this unit. Marketplace issue #873 and publication remain
  owner-controlled and out of scope.

Bounded outcome:

Implement one generic standings/league-view vertical slice. Prefer a pure
provider-neutral standings model plus one provider fixture path and the
smallest QML route needed to show a bounded standings list on an existing
league destination. Selecting a standings team may expose the existing
favorite action if that is already structurally safe; do not redesign the
entire panel. If the current provider payloads cannot support a reliable
generic shape, document the smallest adapter contract and stop after the pure
model/fixture work rather than inventing data.

Required checks and stop condition:

- Add fixture-driven coverage for ordering, missing fields, empty standings,
  malformed provider input, and the selected-team/favorite route if changed.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, real-import-
  path `qmllint` over changed QML, and `git diff --check`.
- On actual Omarchy, rescan the linked plugin, inspect the Quickshell log, and
  manually exercise the changed league view if QML behavior changed. Do not
  report an Omarchy check as passing unless it actually ran there.
- Stop before game-detail drill-down, compact/full bar modes, live rotation,
  provider fallback chains, pregame/close alerts, new leagues, niche adapters,
  packaging, tagging, pushing, releases, or Marketplace actions.
- Do not weaken existing acceptance gates or change the public README unless
  the supported product contract actually changes.

At completion, update `roadmap.md` with milestone status, evidence, decisions,
and a dated handoff; replace this file with the next single bounded prompt;
and create one atomic Conventional Commit-style commit only after the gate
passes. Use no subagents unless an independent read-only investigation would
materially improve confidence.
