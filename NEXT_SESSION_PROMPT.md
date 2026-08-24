Work in `/home/joeg/Projects/sportray` on the next bounded Marketplace
publication-handoff unit: perform a later read-only public-listing recheck of
the already published Sportray listing and existing Marketplace issue #873.
Do not create a duplicate issue, edit labels, or apply Marketplace approval
labels.

Before any edit or remote action, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and the latest roadmap/review
handoff. This checkout intentionally has no `docs/upstream-contract.md`;
verify any Omarchy/Quickshell boundary against installed Omarchy 4.0.0-1 and
Quickshell 0.3.0.r20 sources. Inspect `git status`, branch, recent commits,
`manifest.json`, `CHANGELOG.md`, local tags, the existing tag relation,
`MARKETPLACE_SUBMISSION.md`, issue #873, all comments, and the published
listing. Preserve unrelated changes.

Verified current state:

- Issue #873 is the single Sportray submission. It is closed with exactly
  `submission`, `validated`, `listed`, and `approved-and-verified` labels.
  The latter listing state was observed from Marketplace automation; do not
  apply or edit those labels.
- Its exact title is `[Plugin]: Sportray`, and its body matches
  `MARKETPLACE_SUBMISSION.md` exactly. Metadata is repository URL
  `https://github.com/joega/sportray`, category `Widgets`, tags
  `bar, quickshell`, and suggested tag `sports`.
- Its three comments report Quattro compatibility and manifest version
  `1.0.0-rc.8` at `0b0f6ca`, an automated security-baseline pass at exact
  commit `0b0f6ca898c481fe93437a8f765edfd450fe700d` with no findings or
  capabilities, and publication/verification of Sportray at
  `https://omarchyplugins.com/plugin.html?id=io.github.joega.sportray`.
- Local `HEAD` and public `origin/main` are
  `0b0f6ca898c481fe93437a8f765edfd450fe700d`. `manifest.json` carries the
  owner-assigned local version `1.0.0-rc.8`; the tree remains unreleased and
  untagged. The annotated `v1.0.0-rc.7` tag still peels to
  `de450941b5846914e1f8200f1a74ccf0a301428c`.
- The owner authorized only the personally captured root `preview.png` as
  shown, including its visible provider and team marks. Claim no rights for
  other assets.
- Installed Omarchy owns `/usr/bin/omarchy-launch-browser`; installed
  Quickshell exposes the existing QString-list `Quickshell.execDetached`
  method. ESPN remains an undocumented provider interface.

Bounded outcome:

Read the current public listing and issue #873 again, confirm that the
published listing still corresponds to the exact issue metadata/body and
verified commit, record any change in `roadmap.md` and
`PUBLIC_CONSUMPTION_REVIEW.md`, and refresh this prompt with the next single
bounded unit. Do not rerun publication workflows merely to recheck state.

Required checks and stop condition:

- Confirm the exact listing URL, issue title/body, labels, metadata, all
  comments, listed version, source/commit identity, and any maintainer request.
- Run `git diff --check` if local documentation is edited.
- Do not create or duplicate issues, edit labels, apply `approved-and-verified`,
  package, tag, move `v1.0.0-rc.7`, push, or create a GitHub Release.
- Stop and ask the owner if Marketplace requests repository changes, new
  rights claims, a different target commit, or any action beyond a read-only
  check. If a newer listed version is explicitly requested, do not act unless
  owner direction authorizes the Marketplace verification form’s “Verify and
  publish a newer upstream commit” action with the full 40-character target
  SHA.
- Use no subagents unless an independent read-only Marketplace audit materially
  improves confidence.

Known risks: the candidate is published from an unreleased, untagged `rc.8`
tree; the existing `v1.0.0-rc.7` tag remains older; the preview contains
provider/team marks under the owner-authorized decision; ESPN is undocumented;
and publication remains Marketplace-owner controlled. When the gate passes,
update the roadmap and review handoff again, refresh this prompt, and create
one atomic Conventional Commit-style commit only for those local
documentation changes.
