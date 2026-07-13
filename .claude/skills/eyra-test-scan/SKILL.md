---
name: eyra-test-scan
description: |
  Test gap analysis for a new feature, milestone, or branch in the Eyra Next platform (mono repo).
  Scans changed production code and checks whether there are enough unit tests (ExUnit), feature
  tests (Wallaby), and E2E tests (Playwright). Output is concrete advice for developers,
  plus the question whether an E2E spec is still missing.
triggers:
  - test-scan
  - /test-scan
  - test gap
  - test gap analysis
  - test coverage
  - test coverage check
---

# Test Scan — gap analysis for Eyra Next

This skill helps assess a new feature or milestone:

1. Whether the developers have written enough unit/feature tests (if not → advice back).
2. Whether an E2E spec is still needed (if so → `/e2e-create`).

## Step 1 — Determine scope

Ask (if not given): what is the scope?

- **Branch** — a feature branch that is still open. Use `git diff develop..HEAD --stat`
  to find changed files.
- **PR number / URL** — `gh pr view <id>` to get the branch, then diff as above.
- **Free-form** — a feature is mentioned by name. Then ask which modules that touches or search
  with `grep -r` for relevant symbols.

## Step 2 — Read the conventions

Before judging, **first read** the current test conventions in mono. Do a find — paths can shift:

```bash
find core/test -maxdepth 4 -name CLAUDE.md
find core/test -maxdepth 4 -name AGENTS.md
```

Expected (at time of writing): `core/test/.claude/CLAUDE.md` (the 5 rules: atomic, guards first,
let-it-crash, standard tuples, pattern match in function heads), `core/test/CLAUDE.md`
(Wallaby selectors, signal isolation), `core/test/e2e/CLAUDE.md` (Playwright conventions). Read
all of them before formulating advice.

## Step 3 — List production code

```bash
git diff develop..HEAD --stat -- 'core/lib/**' 'core/systems/**' 'core/frameworks/**'
git diff develop..HEAD --stat -- 'core/test/**'
```

Make two lists:
- **New or heavily changed production modules** (high additions/deletions ratio).
- **Test files changed at the same time**.

## Step 4 — Check per module

For each production module:

1. Does a `*_test.exs` exist at the mirrored path in `core/test/`?
   - E.g. `core/systems/foo/bar.ex` → `core/test/systems/foo/bar_test.exs`
2. Count atomic tests:
   ```bash
   grep -c "^    test " core/test/systems/foo/bar_test.exs
   ```
3. **LiveComponent or LiveView?** (grep for `use Phoenix.LiveComponent` / `use Phoenix.LiveView`)
   - Check whether the test uses `live_isolated`. If not → flag this specifically; LiveComponent
     state should be tested at the unit level, not deferred to feature/E2E.
4. **Public functions without guards?** Flag it, since rule 3 says: guards first, with tests.
5. **Coverage number** for the touched paths:
   ```bash
   cd core && mix test --cover test/systems/foo
   ```
   (Only run this if the branch is checked out locally and the DB is ready — `mix ecto.migrate`
   in `core/` if in doubt.)

## Test distribution — target ratio

The agreed distribution for this codebase:

| Layer | Tool | Style | Share |
|---|---|---|---|
| Unit | ExUnit (Phoenix) | **Whitebox** — internal logic, edge cases, regression safety | 90% |
| Feature | Wallaby (headless browser, mini-E2E) | **Greybox** — UI flows, multi-user or JS hooks | 9% |
| E2E | Playwright | **Blackbox** — happy path as the user walks through it, one flow per critical system | 1% |

Use this as a benchmark when assessing a PR. If a PR adds relatively many feature or E2E tests compared to unit tests, that's a flag.

## Step 5 — Assess feature tests

The default for UI work is **unit** via `live_isolated`, not feature. Feature is only needed if:

- Two users genuinely participate at the same time (`@sessions 2` in Wallaby), or
- JavaScript hooks that you can't replicate in `live_isolated`.

For the PR scope: check `core/test/features/` to see whether a relevant flow test already exists.
If the PR adds such a flow, ask yourself whether it really can't be covered at the unit layer —
flag that in your advice if the choice isn't obvious.

## Step 6 — Check E2E

E2E tests the happy path as a user walks through it — one flow per critical system. Check `core/test/e2e/`:

```bash
ls core/test/e2e/*.spec.ts
```

If the PR introduces a new critical system (= a new top-level user journey) without an existing
E2E spec → note this as a candidate for `/e2e-create`. If the system already has a spec →
add nothing, E2E is not an edge-case layer.

## Step 7 — Write the report

Output in this format:

```
## Test Scan — <scope>

### Unit (ExUnit) — advice to developers
- <module>: <finding>
  Suggestion: <concrete action>

### Feature (Wallaby) — advice to developers
- <flow>: <finding>
  Suggestion: <concrete action>

### E2E (Playwright)
- [ ] E2E spec missing for <system> → candidate for /e2e-create
- [x] Existing spec covers the system (<spec.ts>) — nothing to add

### Summary
- Production lines added: <N>
- Test lines added: <M>
- Ratio: <M/N> (red flag if < 1:1 for core components)
- New test distribution: <X>% unit / <Y>% feature / <Z>% E2E (target: 90/9/1)
```

## Important do's and don'ts

- **Don't advise adding feature tests if the unit layer can do it better** — the test pyramid
  says: focus on unit, feature is the middle ground, E2E is the happy path. Be strict.
- **Flag a LiveComponent without a `live_isolated` test** as a recurring gap — this is often forgotten.
- **Buggy-behavior tests that break after a fix** are normal — if you see these, no red flag, but do mention they'll need action after the fix.
- **Mix tasks don't clash with `mix phx.server`** as long as they don't start an endpoint. `mix ecto.migrate`
  and `mix seed` are safe in parallel, `mix run priv/repo/seeds.exs` is not (it starts the whole app).
- **No recommendation to run `mix test --cover` on the whole suite** — only on the touched
  paths. Otherwise too slow and not PR-relevant.
- Path shifts: if `find core/test -name CLAUDE.md` returns less than before, check whether the content
  has moved to `AGENTS.md` or another location before basing your judgment on an outdated
  document.
