Work in `/home/joeg/Projects/sportray` on the next bounded product unit:
implement a verified NHL standings adapter and standings presentation
projection, based on the private feature-parity backlog in `competition.md`.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, `competition.md`, and this latest
handoff. The upstream-contract file is intentionally absent; verify current
Omarchy/Quickshell boundaries against installed sources. Inspect `git status`,
the current branch, recent commits, the latest roadmap handoff, NHL provider
code, existing ESPN standings model/presentation, fixtures, and tests.
Preserve unrelated changes, especially the existing deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- Sportray has eight leagues, canonical favorites, Following and league views,
  date navigation, ESPN-backed standings, a local keyboard-accessible game
  detail view, compact/full ambient modes, live-favorite rotation, adaptive
  polling, bounded caches/responses, source links, settings, accessibility,
  and favorite-only start/score/final notifications.
- NHL is intentionally scores-only because no verified NHL standings contract
  has been accepted yet. ESPN standings are already provider-neutralized and
  should remain the model/presentation reference.
- `competition.md` records the current catalog peers and the remaining parity
  backlog. After NHL standings, the recommended slices are one optional rich
  detail section and one pregame reminder policy.
- Provider parsing stays in `providers/`; QML consumes normalized projections.
  Preserve the no-account/no-backend/no-daemon default and all response,
  settings, notification, and privacy bounds.
- No public or Marketplace action is in scope. `origin/main` still contains
  historical private planning/Marketplace files; do not push or attempt remote
  cleanup in this unit.

Bounded outcome:

Inspect installed/current NHL source and identify one reliable standings
payload shape. Add a pure NHL standings parser/projection, a bounded fixture,
and the smallest existing league-view integration needed to show standings
with sport-appropriate ordering and safe missing-field behavior. Keep team
identity canonical and preserve existing favorite actions if the route already
supports them. If no reliable standings payload can be verified, implement
only the pure contract/fixture rejection path, document the blocker, and stop.

Required checks and stop condition:

- Add fixture-driven coverage for valid ordering, ties or missing values,
  malformed entries, empty standings, canonical team identity, and favorite
  routing if changed.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, real-import-
  path `qmllint` over changed QML, and `git diff --check`.
- On actual Omarchy, rescan/restart the linked plugin as required by the
  installed host, inspect the Quickshell log, and manually exercise an NHL
  league view if QML behavior changes. Do not claim runtime success without an
  actual Omarchy check.
- Stop before rich game detail, pregame/close alerts, provider fallback
  chains, broader team discovery, calendar redesign, specialist sports,
  packaging, tagging, pushing, releases, or Marketplace work.

At completion, update `roadmap.md` with evidence, decisions, and a dated
handoff; replace this file with the next single bounded prompt; and create one
atomic Conventional Commit-style commit only after all gates pass. Use no
subagents unless an independent read-only NHL contract investigation would
materially improve confidence.
