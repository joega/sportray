Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
add one pure, fixture-driven provider-fallback chain policy under `model/`
that describes ordered per-league provider fallback decisions without wiring
it into QML or services in this unit. This is the last unimplemented
capability of the recorded minimum competitive baseline; keep it a pure
model/policy slice exactly like the earlier rotation and countdown policy
units.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and
the latest handoff. `docs/upstream-contract.md` is intentionally absent in
this checkout; inspect the installed Omarchy and Quickshell sources directly
for any host-boundary claim and record any material deviation in `roadmap.md`
and later the README. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`, with `HEAD` at or beyond the 2026-08-24
  post-filter calendar consistency audit handoff; `origin/main` lags locally.
  Do not push or change remote state.
- The calendar slice and its keyboard filter route are implemented and
  runtime-verified; the 2026-08-24 read-only audit found no contradictions
  between README calendar claims, roadmap evidence, and source.
- The deterministic suite passes with 200 tests; plugin validation,
  real-import-path QML lint (exit 0 with established standalone warnings), and
  `git diff --check` all pass as of the audit handoff.
- Existing per-league fetch ownership lives in `services/LeagueFetch.qml` and
  the shared scheduler; providers live only in `providers/`. Provider parsing
  must stay out of QML per the architecture guardrails.

Bounded outcome:

Implement one new pure JavaScript policy module (for example
`model/ProviderFallbackPolicy.js`) that takes an ordered candidate list for
one league and caller-supplied health/failure state, then deterministically
returns which provider to try next, when to stay on the current one, and a
bounded exhausted state. It must fail closed on malformed input, own no
timers, requests, or settings, and never import provider parsing. Add one
sanitized fixture plus fixture-driven tests covering healthy-primary
retention, fallback after failure, recovery back to the primary, malformed
input rejection, and bounded exhaustion. Do not modify any QML file, service,
provider, endpoint, polling cadence, or settings schema in this unit.

Required checks:

- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files.
- No QML behavior change is expected, so no shell restart is required unless
  the unit accidentally changes a QML boundary, in which case stop and
  document instead of expanding scope.

Known risks and stop conditions: ESPN remains an undocumented API; the
installed host may require `omarchy restart shell` to load edited QML;
pointer injection remains unavailable. Stop before wiring the policy into
`LeagueFetch.qml`/scheduler, changing request paths or endpoints, adding
leagues, settings persistence, packaging, tagging, pushing, release, or
Marketplace work. A later unit wires the accepted contract into the existing
fetch boundary only after this pure contract passes its gates.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
