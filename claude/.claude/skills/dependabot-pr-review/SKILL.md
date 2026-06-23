---
name: dependabot-pr-review
description: Use when reviewing, resolving, merging, or managing a Dependabot PR, including grouped and security bumps. Not for general PR review, hand-written dependency changes, or non-dependency PRs.
---

# Dependabot PR Review

Confidence-building workflow for Dependabot PRs. The scope of checks scales with the risk of the bump.

**Why we re-author by default:** Dependabot-authored PRs run under `Secret source: Dependabot`, which cannot see Actions-scoped secrets. Tests that need API keys, ECR tokens, or any Actions-only secret will fail on every dependabot PR regardless of the bump quality. Re-authoring under your own actor restores full CI signal. The dependabot PR is kept open while there's still a chance the bump needs to change, so we can drive it with `@dependabot` slash commands (rebase, recreate, ignore-version).

## Workflow

```
1. CLASSIFY     → Identify bump scope (patch / minor / major) and risk surface
2. FRESHNESS    → If branch is stale or old, comment `@dependabot rebase` first
                   (in case a newer version exists, or dependabot opens a replacement PR)
3. RE-AUTHOR    → Open your own PR from the dependabot branch; link the tracking ticket
                   ── CI starts on your PR now; let it run in parallel with the steps below ──
4. ISOLATE      → Fetch the dependabot branch into a worktree
5. INSPECT      → Read release notes, CVE notes, and the actual file diff
6. BUILD        → Compile the project from a clean state
7. TEST         → Run the relevant test suites
8. SMOKE        → Boot the app and hit health / key endpoints
9. SYNC (if needed) → Use `@dependabot rebase/recreate` on the dependabot PR, then force-push onto your branch
10. RECORD      → Post a QA summary comment on your PR, approve, and merge
11. CLOSE       → After merge (or earlier when bump is final), comment `@dependabot close` on the original PR
```

## Step 1: Classify the Bump

Read the PR title and diff. Determine risk level:

| Scope | Examples | Risk | Required checks |
|-------|----------|------|-----------------|
| **Patch** | `1.2.3 → 1.2.4` | Low | Build + unit tests |
| **Minor** | `1.2.3 → 1.3.0` | Medium | Build + all tests + smoke |
| **Major** | `1.2.3 → 2.0.0` | High | All of the above + manual integration test + breaking-change review |
| **Group** | `Bump the minor-and-patch group with N updates` | Medium | Treat as minor; check each member |
| **Security** | GHSA / CVE referenced | Cross-cutting | Verify advisory applies; do not skip tests |

**Production vs test/build dep:** If the dependency is build-only (test runners, linters, pitest, etc.) the runtime risk is lower but the CI risk is higher — focus on running CI locally.

## Step 2: Check Branch Freshness

Before re-authoring, check whether the PR is stale (opened long ago, behind default branch, or sitting through several main-branch commits). If it is, ask dependabot to rebase **first** — there may be a newer upstream version since the PR was opened, and the rebase will pick it up.

```bash
gh pr view <PR> --json mergeStateStatus,headRefOid,baseRefName,createdAt -q '.'
git fetch origin <default-branch>
gh pr view <PR> --json commits -q '.commits[0].oid' | xargs -I {} git merge-base {} origin/<default-branch>
```

If the PR is more than a few days old or the merge-base is older than `origin/<default-branch>~5`, rebase first:

```bash
gh pr comment <PR> --body "@dependabot rebase"
```

Wait for dependabot to push the rebase (usually 1–5 minutes). One of two things happens:

1. **Same PR, new HEAD** — dependabot force-pushes onto the same branch. The new HEAD may bump to a higher version than the original PR — re-read the title and diff before continuing.
2. **PR closed, replacement opened** — dependabot replies *"Looks like these dependencies are updatable in another way, so this is no longer needed"*, closes `$ORIG`, and opens a fresh PR (often with a different update count). This commonly happens with grouped updates where the set of eligible deps has changed since the original PR was opened.

After the rebase reply, check both states:

```bash
gh pr view "$ORIG" --json state,closedAt
# If state=CLOSED, find the replacement:
gh pr list --search "author:app/dependabot is:open" --json number,title,headRefName,createdAt
```

If the original closed, switch `$ORIG` to the replacement PR number and re-read Step 1 (the bump scope may have shifted).

**Why this matters:** A stale dependabot PR can be superseded by a newer version that closes additional CVEs or fixes the bug you're about to test. Re-authoring the old bump wastes a cycle. Always start from the freshest dependabot proposal.

If freshness is fine (PR opened today, branch aligned), skip the rebase and go straight to Step 3.

## Step 3: Re-author the PR

Push the dependabot commits under a new branch in your own name and open a fresh PR. The new PR's actor is you, so CI runs with `Secret source: Actions`.

**Check project conventions first.** Before using the default template below, look in `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` for the project's branch naming, commit prefix, and PR title rules. Many repos require shapes like `SD-123-kebab-description` (no `chore/` prefix) or `dependabot/<ticket>` — using the template default here creates needless friction at review time. The same applies to the PR title and the commit message format.

```bash
ORIG=<dependabot-pr-number>
BRANCH=$(gh pr view "$ORIG" --json headRefName -q .headRefName)
BASE=$(gh pr view "$ORIG" --json baseRefName -q .baseRefName)
TICKET=SDB-XXX                          # tracking ticket, or leave blank
# Default — replace with the project's convention if one is documented
NEW_BRANCH="chore/${TICKET:-deps}-$(gh pr view "$ORIG" --json number -q .number)"

# Push the same commits (no rewrite, no cherry-pick) under a new branch
git fetch origin "$BRANCH"
git push origin "origin/$BRANCH:refs/heads/$NEW_BRANCH"

# Open the re-authored PR — link both the ticket and the original dependabot PR
TITLE=$(gh pr view "$ORIG" --json title -q .title)
gh pr create --base "$BASE" \
             --head "$NEW_BRANCH" \
             --title "${TICKET:+$TICKET: }$TITLE (re-authored from #$ORIG)" \
             --body "Re-authored from #$ORIG so CI runs with \`Secret source: Actions\`. Original dependabot PR cannot access Actions-scoped secrets required by integration tests. Same commits, same diff.

Original: #$ORIG"

# Leave a back-link on the dependabot PR so the trail is visible from both sides
gh pr comment "$ORIG" --body "Re-authored as the linked PR for CI secret-scope reasons. This PR stays open as the bump source-of-truth — use \`@dependabot rebase\`/\`recreate\` here to update the bump, then I'll force-push the new HEAD onto the re-authored branch."
```

**Keep the dependabot PR open while you may still need to change the bump** — `@dependabot rebase` / `recreate` only work on an open dependabot PR. Once you're confident the bump set is final (diff inspected, local + CI verification under way, no expected version churn), it's fine to close `$ORIG` early — for example when your re-authored PR is waiting on an external reviewer and leaving the dependabot PR open is just noise. Default is keep-open; close early is a judgement call, not a rule.

**Ticket linking lives on your PR, not the dependabot PR.** Your PR title is the merge target and won't be rewritten. No need for the re-link-after-rebase dance.

**Don't wait on CI before starting local verification.** Once the re-authored PR is open, CI runs on its own clock. Move straight on to Steps 4–8 (worktree, inspect, build, test, smoke) in parallel — they don't depend on CI's verdict, and CI checks only become useful *after* you've already done local work to compare against. Treat CI as a second opinion, not a gate.

## Step 4: Fetch into a Worktree

Never check out the branch in the main working directory.

```bash
git fetch origin "$NEW_BRANCH"
git worktree add "../$(basename "$PWD")-${TICKET:-deps}-$ORIG" "$NEW_BRANCH"
cd "../$(basename "$PWD")-${TICKET:-deps}-$ORIG"
```

## Step 5: Inspect the Diff

Always look before running:

1. **Dependabot PR body** — release notes, commit list, compatibility score. Read them on the original (`gh pr view $ORIG`).
2. **File diff** — `gh pr diff <your-pr>` or `git diff origin/<default-branch>...HEAD`.
   - Only lock files (`gradle.lockfile`, `package-lock.json`, `Pipfile.lock`)? Lower risk.
   - Manifest changes (`build.gradle`, `pom.xml`, `package.json`)? Check for unintended scope changes.
   - Transitive dependencies updated? Note major bumps you didn't expect.
3. **Upstream release notes** — For minor / major / security bumps, open the linked release on GitHub. Look for: deprecations, removed APIs, behavioural changes, configuration changes.
4. **Search the codebase** for usage of the dependency's APIs that may have changed.

## Step 6: Build

**Detect the build tool first.** Look at the manifest in the repo root before running anything — the commands below are a Gradle / Spring Boot example, not the canonical path. Common cases:

| Manifest | Build tool | Example build command |
|----------|------------|-----------------------|
| `build.gradle` / `build.gradle.kts` | Gradle | `./gradlew clean build -x test` |
| `pom.xml` | Maven | `./mvnw -DskipTests verify` |
| `package.json` | npm / yarn / pnpm | `npm ci && npm run build` |
| `pyproject.toml` / `requirements.txt` | Python | `pip install -e . && python -m build` |
| `Cargo.toml` | Cargo | `cargo build` |
| `go.mod` | Go | `go build ./...` |

Use the project's actual build (not just compile). Gradle / Spring Boot example:

```bash
./gradlew clean build -x test     # quick compile + assemble
```

If the build relies on code generation, run that too (e.g. OpenAPI generators, MapStruct annotation processing happens via `build`).

## Step 7: Test

Run the suites in increasing scope, using the test runner for the build tool detected in Step 6 (Gradle / Spring Boot example below; for Maven use `./mvnw test` / `verify`, for npm `npm test`, etc.):

```bash
./gradlew test                    # unit
./gradlew integrationTest         # integration (if separate task)
./gradlew check                   # static analysis + tests
```

For minor or major bumps, also run:

- **Mutation testing** if the dep affects pitest, JUnit, or testing libs: `./gradlew pitest` (slow).
- **Architecture tests** if the project has ArchUnit or similar.
- **Linting / formatting** — Spotless, ktlint, ESLint, ruff. A bumped formatter may rewrite the world.

CI on your re-authored PR runs with full secret scope — use it as the authoritative signal. The local run catches environment-specific drift (Java version, locale, line endings) before pushing.

## Step 8: Smoke Test

Boot the application against real infrastructure, using the project's run command (Gradle / Spring Boot example below; e.g. `./mvnw spring-boot:run`, `npm start`, `python -m app`):

```bash
docker compose up -d              # DB, message broker, etc. (if the project uses them)
./gradlew bootRun                 # or equivalent
```

Then verify:

| Check | Purpose |
|-------|---------|
| `GET /health` returns 200 | App started, DB reachable |
| Hit one or two key endpoints | Confirms framework wiring (Spring beans, JSON serialisation) still works |
| Tail logs during startup | Catches deprecation warnings, missing-bean errors, config conflicts |
| If migrations exist | Confirm Liquibase / Flyway runs cleanly against a fresh DB |

For frontend deps: start the dev server, navigate to one page that exercises the changed lib.

## Step 9: Sync from Dependabot (if the bump needs to change)

If the bump version is wrong, conflicts emerge, or a newer release has dropped since you re-authored, drive the change through the dependabot PR — it stays the source of truth for the bump artifact.

```bash
# Ask dependabot to refresh
gh pr comment "$ORIG" --body "@dependabot rebase"     # or "@dependabot recreate" if rebase won't resolve

# Wait for dependabot to push (poll headRefOid)
gh pr view "$ORIG" --json headRefOid -q .headRefOid

# Force-push the new HEAD onto your branch
git fetch origin "$BRANCH"
git push --force-with-lease origin "origin/$BRANCH:refs/heads/$NEW_BRANCH"
```

Then re-run Steps 5–8 (inspect, build, test, smoke) on the refreshed branch. Your PR title doesn't get rewritten — dependabot only rewrites titles on its own PRs.

## Step 10: Record and Merge

1. Post a QA summary comment on **your** PR using the `qa-pr-comment` skill. Include:
   - Bump scope and classification
   - Local build / test / smoke results
   - Any deprecation warnings observed
   - Anything skipped and why
2. Approve and merge your PR through the normal review/merge flow.
3. Clean up the worktree: `git worktree remove ../<dir>`.

## Step 11: Close the Dependabot PR

Close the original dependabot PR once you're confident no further bump churn is needed — typically after your re-authored PR merges, but earlier is fine if review is dragging and you're sure the bump set is final (see Step 3's note).

```bash
gh pr comment "$ORIG" --body "Superseded by the re-authored PR. Closing."
gh pr comment "$ORIG" --body "@dependabot close"
```

Posting the comment is the action that matters — dependabot is third-party and reacts on its own clock; don't gate the rest of the workflow on the PR state flipping to CLOSED.

**Important caveats:**
- Do **not** `@dependabot ignore` the dependency or version — you still want future bumps. Just close this single PR.
- The next cycle will open a fresh dependabot PR if a newer version exists. Manually close any subsequent dependabot PR that ships a bump you've already merged.
- The commit author stays `dependabot[bot]` on the merged commits, which is fine — secret scope is determined by PR/event actor, not commit author.

## Dependabot Commands Reference

Dependabot reads slash-style comments on its own PRs. Useful ones:

| Comment | Effect |
|---------|--------|
| `@dependabot rebase` | Rebase the PR on top of the default branch (use when stale, or to pick up a newer upstream version). |
| `@dependabot recreate` | Discard the branch and recreate from scratch — use when rebase won't resolve conflicts. **Destructive** — kills any human commits on the branch. |
| `@dependabot close` | Close the PR. Dependabot will not reopen the same update. Use after your re-authored PR merges. |
| `@dependabot reopen` | Reopen a previously closed PR. |
| `@dependabot ignore this minor version` | Skip the specific minor version forever. |
| `@dependabot ignore this major version` | Skip the specific major version forever. |
| `@dependabot ignore this dependency` | Ignore the dependency entirely (until config changes). |
| `@dependabot unignore this dependency` | Reverse the above. |
| `@dependabot show <dependency-name> ignore conditions` | List active ignore rules for a dependency. |
| `@dependabot use these labels: foo, bar` | Apply labels to dependabot PRs going forward. |
| `@dependabot use these reviewers: @alice, @bob` | Set default reviewers. |
| `@dependabot use these assignees: @alice` | Set default assignees. |

`@dependabot merge` / `squash and merge` / `cancel merge` are **not used** in this workflow — we merge our own PR instead.

Post via `gh pr comment <PR> --body "@dependabot <command>"`.

**Choosing between commands:**
- Stale branch or want a newer upstream version → `rebase`.
- Branch is broken and rebase won't resolve → `recreate`.
- Major bump that the project will never adopt (e.g. Java 8 project, lib went Java 17-only) → `ignore this major version`, then close both PRs.
- Repeatedly noisy minor that breaks a transitive → `ignore this minor version` for one cycle, revisit later.

## Additional Checks Worth Considering

Add these when the bump touches sensitive areas:

- **Security advisories** — `gh api repos/{owner}/{repo}/dependabot/alerts` to see if the bump closes one.
- **License changes** — A dependency may relicense between versions. Check `LICENSE` in the new release.
- **Bundle / artifact size** — For frontend deps, compare bundle output. For Java, check `./gradlew dependencies` diff.
- **Binary compatibility** — For library projects, run `revapi` / `japicmp` if available.
- **Performance smoke** — If the dep is on a hot path (JSON, DB driver, HTTP client), run a quick benchmark.
- **Downstream consumers** — If this repo is a library, check that key consumers still build against the new version.

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Merging because "CI is green" without reading release notes | CI tests what you wrote; release notes warn about what you didn't think to test. Read both. |
| Skipping smoke test on a "test-only" dep | Test infrastructure changes can mask broken tests as passing. Smoke = run the actual test runner output. |
| Forgetting to link the ticket | Jira loses the audit trail. Always prepend `SDB-XXX:` to your re-authored PR title. |
| Treating grouped updates as one risk | Each member can break independently. Inspect every member of the group. |
| Reviewing on the main worktree | Pollutes the working dir and risks contaminating in-progress work. Always use a worktree. |
| Approving with deprecation warnings | They become errors in the next minor. Note them as follow-ups. |
| Closing the dependabot PR before merging your re-authored one | You lose the ability to `@dependabot rebase/recreate` if the bump needs to change. Keep it open until merge. |
| Editing the bump directly on your branch instead of via dependabot | Dependabot is the source of truth for the bump artifact. Use `@dependabot rebase/recreate` and force-push the result onto your branch (Step 9). |
| Re-authoring a stale PR without rebasing first | A newer upstream version may exist. Always check freshness in Step 2 before re-authoring. |
| **Stale branch vs pre-migrated test image** | If the project's test DB image ships with pre-applied schemas (e.g. `postgres-multi-db:<tag>`), a dependabot branch older than recent migrations will fail locally even when CI is green. Step 2's freshness rebase usually resolves this. |
| Diagnosing a "regression" before confirming CI's verdict | Local-only failures with a green CI usually mean environmental drift. Before raising the alarm, run the same test class on the default branch locally — if it passes there but fails on the bump branch, *then* confirm CI ran the full suite before concluding. |

## Local-vs-CI Discrepancy Triage

When local tests fail but CI on your re-authored PR passes, do not assume the bump caused it. Work this list:

1. Confirm CI actually ran the failing tests — check the workflow log for the test count, and that no `*-tests` job was skipped (path filters or `if:` conditions).
2. Run the same failing test class against the default branch locally. If it passes there but fails on the bump branch, the difference is something *between* the branches.
3. If the project uses **pre-migrated DB images** (Postgres with baked schemas, Mongo with seed data, etc.): the image tag floats. Local pulls may be newer than what CI used. Compare the image's creation date to the branch's base commit date.
4. Refresh the bump via Step 9 (`@dependabot rebase` on the original PR, then force-push). Schema-drift failures usually disappear.
5. Only after 1–4 still fail, suspect the dependency.

## Quick Reference Commands

```bash
# Identify the PR
gh pr list --search "dependabot" --state open
ORIG=<dependabot-pr-number>
TICKET=SDB-XXX
BRANCH=$(gh pr view "$ORIG" --json headRefName -q .headRefName)
BASE=$(gh pr view "$ORIG" --json baseRefName -q .baseRefName)
NEW_BRANCH="chore/${TICKET:-deps}-$ORIG"

# Freshness rebase (only if stale)
gh pr comment "$ORIG" --body "@dependabot rebase"

# Re-author under your own actor
git fetch origin "$BRANCH"
git push origin "origin/$BRANCH:refs/heads/$NEW_BRANCH"
gh pr create --base "$BASE" --head "$NEW_BRANCH" \
  --title "$TICKET: $(gh pr view "$ORIG" --json title -q .title) (re-authored from #$ORIG)" \
  --body "Re-authored from #$ORIG for Actions secret scope. Original: #$ORIG"
gh pr comment "$ORIG" --body "Re-authored as linked PR; this stays open as bump source-of-truth."

# Worktree
git fetch origin "$NEW_BRANCH"
git worktree add "../$(basename "$PWD")-${TICKET:-deps}-$ORIG" "$NEW_BRANCH"

# Inspect
gh pr view "$ORIG" --comments
gh pr diff "$ORIG"

# Verify (Gradle / Spring Boot example)
./gradlew clean build
./gradlew check
docker compose up -d && ./gradlew bootRun
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8080/health

# Sync if the bump needs to change
gh pr comment "$ORIG" --body "@dependabot rebase"   # or "recreate"
git fetch origin "$BRANCH"
git push --force-with-lease origin "origin/$BRANCH:refs/heads/$NEW_BRANCH"

# After merge: close the dependabot PR
gh pr comment "$ORIG" --body "Superseded by merged re-authored PR. Closing."
gh pr comment "$ORIG" --body "@dependabot close"

# Cleanup
git worktree remove "../$(basename "$PWD")-${TICKET:-deps}-$ORIG"

# Other dependabot commands as needed
gh pr comment "$ORIG" --body "@dependabot ignore this major version"
gh pr comment "$ORIG" --body "@dependabot close"
```
