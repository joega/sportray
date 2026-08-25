Work in /home/joeg/Projects/sportray on exactly one bounded work unit:
Level the Field C2 — Provider range reconnaissance and chunk policy.

Before editing or testing, read AGENTS.md, README.md, roadmap.md including its
latest handoff, competition.md, LEVEL_THE_FIELD_SPRINT.md, and this prompt in
full. docs/upstream-contract.md is intentionally absent; inspect the installed
Omarchy and Quickshell sources directly for every host-boundary claim and
record any material deviation in roadmap.md. Inspect git status, branch, and
recent commits. Preserve unrelated changes, including the absence of
MARKETPLACE_SUBMISSION.md; do not restore or stage it. Use subagents only for
independent read-only provider or host reconnaissance that materially helps.

Verified starting state:

- C1 is the current source slice. CalendarModel produces a Monday-first
  42-cell month projection with adjacent dates, selected/today state, bounded
  counts and favorite markers, and explicit unknown versus known-complete-
  empty state.
- LeagueFetch date-cache entries carry complete true only after successful
  zero-error normalized snapshots. MonthCalendar.qml replaces the old
  CalendarWeekStrip.qml and uses the existing selected-date fetch path. No
  calendar schedule owner, range request, new endpoint, timer, Process,
  polling change, response-limit change, or cache widening exists.
- C1 deterministic coverage is 234 passing tests. The summon-helper suite,
  diff check, actual Omarchy plugin validation, and full real-import-path QML
  lint pass. Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  28771c7c74b42e20afca0b1b63980cb46515537 is the current boundary.
- C1 was rendered on actual Omarchy in one shell instance with ping, rescan,
  summon, and fresh-log checks. Keyboard l/j plus Enter selected an adjacent
  month date and triggered the existing fetch route. Pointer and child-panel
  Accessible activation could not be injected reliably and remain explicitly
  unclaimed runtime evidence.

Concrete outcome: complete the C2 provider feasibility gate only. Perform
bounded read-only observations against already accepted provider hosts/routes
for ESPN range behavior across every ESPN-backed league family, NHL schedule
continuation behavior, and MLB StatsAPI only if its already accepted terms and
shape make it a candidate. Record status, advertised content length when
available, event count, date span, continuation/next-page shape, and elapsed
time without retaining long-lived raw payloads. Derive and fixture-test a
pure provider-neutral chunk/request-window policy with hard request, byte,
event, date-span, and concurrency bounds.

Hard scope limits:

- Do not add QML, visible-month hydration, a schedule fetch owner, cache
  widening, range requests in runtime, new endpoints, timers, polling changes,
  response-limit changes, settings schema 2, watched games, followed leagues,
  scoring plays, leaders, broadcasts, provider fallback, team-ID
  reconciliation, packaging, tagging, pushing, release, or Marketplace work.
- Do not raise the 2 MiB or 256-event limits, weaken one-in-flight ownership,
  alter notification/privacy/no-daemon boundaries, or infer provider shape
  from a non-evidence response.
- If a provider cannot safely support a full month, preserve the honest C1
  month UI and record an unknown/partial strategy rather than inventing
  completeness.

Required checks:

- Add sanitized fixture evidence and pure policy tests for accepted,
  rejected, malformed, oversized, continuation, date-span, request-count,
  and provider-specific cases. Keep raw payloads out of the repository.
- Add source assertions proving the policy has no QML/network/process/timer
  ownership and that C1 runtime ownership remains unchanged.
- Run ./tests/run-js-tests.sh, ./tests/test-summon-helper.sh, git diff --check,
  omarchy plugin validate "$PWD", and real-import-path qmllint over every QML.
- Recheck installed host sources if any boundary is involved. Runtime shell
  exercise is not required unless C2 changes QML/service/runtime; if it is
  required, confirm one shell, discovery, ping, summon, and fresh clean logs
  on actual Omarchy.

Stop condition: if any accepted provider's range behavior, terms, byte/event
bound, continuation, or date coverage is unresolved, do not add runtime
fetching or widen limits. Record the smallest unresolved decision and leave
C1 behavior intact.

At the end, update LEVEL_THE_FIELD_SPRINT.md with C2 status/evidence, append a
dated milestone/decision/risk/handoff entry to roadmap.md, update competition.md
only if parity evidence changed, and replace this prompt with one
self-contained prompt for exactly C3 or the smallest blocker-resolution unit.
Commit C2 atomically only after all applicable gates pass. Do not push or make
release/Marketplace changes.
