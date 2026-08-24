Work in `/home/joeg/Projects/sportray` on the next bounded roadmap unit:
diagnose and reconcile the installed Omarchy post-rescan
`summon: no live bar widget` warning for the linked Sportray bar-widget route.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify every
Omarchy/Quickshell boundary against installed Omarchy and Quickshell sources.
Inspect git status, current branch, recent commits, the latest ambient-bar
handoff, `manifest.json`, `BarWidget.qml`, `Panel.qml`, the installed widget
registry/bar-slot/rescan/IPC sources, and the existing runtime commands.
Preserve unrelated changes.

Verified current state:

- The live-favorite rotation path is production-wired and unchanged. `Panel.qml`
  keeps the existing favorite-first state, passes normalized today-scoped games
  and caller-owned `ambientNowMs` plus a 60-second presentation cadence to the
  pure rotation policy, and applies rotation only to `live-favorite-count`.
- The new sanitized transition matrix in
  `fixtures/bar-presentation/live-favorite-rotation.json` and the pipeline test
  in `tests/run-js-tests.js` prove cadence advancement, live removal to
  favorite-upcoming/neutral, and countdown reclamation. The complete suite
  passes with 185 deterministic tests.
- `omarchy plugin validate "$PWD"`, full real-import-path QML lint, and
  `git diff --check` pass. No QML or production file changed in the prior unit.
- Actual Omarchy 4.0.0-1 / Quickshell `28771c7` has one running shell, and the
  linked checkout is present at `/home/joeg/.config/omarchy/plugins/
  io.github.joega.sportray`. After rescan and explicit enable, the existing
  toggle/hide IPC commands returned successfully, but the fresh log recorded
  `summon: no live bar widget for: io.github.joega.sportray`; no visual route
  success was claimed. The same log had normal Sportray polling and no
  Sportray exception, QML load failure, binding loop, or rotation error.

Bounded outcome:

Determine whether the warning is an asynchronous host-registration timing
condition, a stale bar-slot/registry state, or a concrete Sportray manifest or
entry-point defect. Reproduce it on the installed shell, wait for asynchronous
widget registration before IPC, inspect registry and slot evidence, and make
the smallest repository change only if a concrete checkout defect is proven.
Keep the existing runtime path intact when the issue is upstream or
environmental.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell sources before editing. Stop and record
  the risk in `roadmap.md` if reliable registration requires a new upstream API,
  plugin kind, timer, provider data, setting, or polling contract; do not alter
  the runtime path to mask the warning.
- Do not add a second timer, endpoint, provider field, setting, polling cadence,
  unrelated UI work, or a new IPC route. Keep provider parsing outside QML.
- If production files change, run `tests/run-js-tests.sh`,
  `omarchy plugin validate "$PWD"`, the real
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
  file, and `git diff --check`. On actual Omarchy, rescan, wait for loader
  settlement, exercise toggle/hide, confirm one shell, and inspect a fresh
  Quickshell log. If no code change is justified, still record the diagnosis
  and the same runtime evidence; do not create a success commit for a purely
  external blocker unless the roadmap explicitly marks the unit blocked.
- Update `roadmap.md` with status, evidence, decisions, risks, and a dated
  handoff. Replace this file with the next self-contained single-unit prompt.
  Create one atomic Conventional Commit-style commit only after a bounded fix
  and every gate pass. Request subagents only for independent read-only
  Omarchy/Quickshell reconnaissance.
