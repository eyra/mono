# Nova migration plan: from eyra/mono to Mica + Next

Status: **draft for review**. Each step gets its own issue in the Next Flux project once the plan is approved. The Feldspar track lives in the Feldspar Flux project and in [eyra/feldspar `doc/nova-migration/plan.md`](https://github.com/eyra/feldspar/blob/develop/doc/nova-migration/plan.md).

Related documents:
- [design.md](./design.md): the design, the inventory and the decisions this plan builds on.

Paths in this document are relative to the repository root and refer to the layout *before* step 8, when `core/` still exists.

## Summary

**The two parts.** `core/` becomes:
- **Mica**: a Mix project with OTP app `:mica`. Modules stay `Core.*`/`CoreWeb.*`. It moves to `novasoftwarefoundation/mica`.
- **Next**: a Phoenix app that depends on Mica through the `Core.Extension` contract. It moves to `eyra/next`.

**How the work is done.** All work happens in this repository on `develop`, in normal small PRs shipped through Next's milestones. There is no long-lived branch and no copy of core.

| Phase | Steps | What happens |
|---|---|---|
| A. Guardrails | 0–2 | Record the rules, remove dead code and Banking, make the target layout visible inside `core/`, add a CI boundary check that only lets violations shrink. |
| B. Decoupling | 3–7 | Open the registries (`Core.Extension`), rename the OTP app, add brand and config seams, open the tool/item registry, move PaNL/VU and other instance specifics to Next, give every table one owner. |
| C. Split | 8–11 | `git mv` into `mica/` and `next/`; assess what becomes public; squash the migration baselines (with a dry run on a production snapshot); create the repositories; cut over Eyra production. |
| F. Feldspar | F1–F3 | Versioned Mica App Protocol, contract tests, and the transfer of `eyra/feldspar` to Nova. Planned in the Feldspar repository; summarized here. |

**Production.** Eyra's production Next keeps running at every step. Phase B steps are invisible to users and are verified by snapshot tests. Three steps carry real operational risk, and each gets a rehearsal on dev/staging and a written rollback:
- step 5: data migration of tool references
- step 8: new build layout and release pipeline
- step 11: production cutover to `eyra/next`

**Decisions and authorizations still needed:**
- removal of `banking_proxy/` (step 1)
- creating `novasoftwarefoundation/mica` and `eyra/next` (step 10)
- using a production snapshot and marking the baselines as applied (steps 9 and 11)
- the production cutover (step 11)
- the Feldspar transfer (F3)
- the future of `eyra/mono` after the split

---

## Decisions this plan builds on

Details and rationale are in [design.md](./design.md#decisions).

- **Option A.** `eyra/next` is the root Phoenix project. Mica is a versioned Mix dependency. Mica's own systems are extensions on the same `Core.Extension` contract. During the migration Next uses `path:` or branch dependencies; afterwards it pins to tags.
- **Governance and graduation.** Mica contains only code under Nova governance. Custom and experimental systems live in the SaaS on the extension contract and can graduate to Mica later. Graphite and Zircon (with Paper, Annotation, Ontology and Onyx) start in Next, as the proof that the contract works.
- **Optional Mica building blocks:** assignment, fund, affiliate, and pool/advert/promotion.
- **Moves to the SaaS (instance specifics):**
  - PaNL names and panl.nl URLs
  - the `:panl` pool seed
  - `participant?(:panl, …)` checks
  - VU student codes
- **`banking_proxy`** is not deployed anywhere and is retired.
- **OTP app** `:core` is renamed to `:mica` as part of the decoupling. Module names stay.
- **Database:**
  - one database per deployment
  - every table has one owner, with its migrations in the owner's repository
  - foreign keys point only from the SaaS to Mica
  - `workflow_tool_refs` and `project_items` become open registry references
  - at the split, the migrations are squashed into Mica and Next baselines, which are marked as applied in Eyra production after a dry run on a production snapshot
- **Layout.** `core/` is split with `git mv` into `mica/` (Mix project) and `next/` (Phoenix app with `{:mica, path: "../mica"}`). Self becomes Mica's reference SaaS inside `mica/`. A separate `novasoftwarefoundation/mica-saas` repository is a later decision.
- **Repositories:**
  - `mica/` goes to `novasoftwarefoundation/mica` with fresh history. Its first commit points back to the `eyra/mono` commit it came from.
  - `next/` goes to `eyra/next`.
  - `eyra/mono` stays available, because Self deployments use it.
- **Deployment model.** One SaaS per deployment. Each operator builds and runs its own SaaS on Mica; multi-tenancy is out of scope.
- **Tracking.** `eyra/mono` work is tracked in Flux project Next; `eyra/feldspar` work in Flux project Feldspar.

## Rules for every step

1. **Small PRs to `develop`.** Each one ships in a regular Next milestone and passes [`test.yml`](../../.github/workflows/test.yml), the smoke tests, and e2e on `eyra-next-dev` and staging. Feature work continues as usual.
2. **The boundary check is a ratchet.** From step 2 on, CI fails on any *new* reference from Mica code to Next code, and on new PaNL/VU/Eyra hard-coding in Mica code. The allowlist of existing violations may only shrink.
3. **Behaviour-preserving refactors prove it with snapshots:**
   - the route table (`mix phx.routes`)
   - the GreenLight permission map
   - the signal handler list
   - the Oban cron list
   - rendered emails and layouts for the Next brand
4. **No destructive schema change in the same release as the code that stops using it.** Use the deferred-drop pattern in [`core/docs/schema-deprecations.md`](../../core/docs/schema-deprecations.md).
5. **New code goes in the folder of its future owner** (`core/mica/…` or `core/next/…`) and uses the contract once it exists.

---

## Phase A — Guardrails

### Step 0 — Credentials, guardrails and communication

- **Goal.** Stop credential exposure, make the rules known, and record the decisions.
- **Credentials: done.**
  - The service-login key was rotated on 2026-10-12 on Fly dev/staging and in the GitHub Actions secret. Dev e2e passes and the old key is rejected.
  - Its value is removed from this repository in [#1858](https://github.com/eyra/mono/pull/1858). Production's separate key is removed through eyra/devops PR #98.
  - The Tidewave token is not a secret (Tidewave documents the team token as safe to commit). The dependency is removed in #1858.
  - History is not rewritten: the repository is public and the values were already exposed, so rotation is the fix.
- **Scope.**
  - Add a pointer to this plan in the root [`CLAUDE.md`](../../CLAUDE.md) and in [`core/CLAUDE.md`](../../core/CLAUDE.md), so agents and developers follow the rules.
  - Brief the teams working on Next and Feldspar.
- **Dependencies.** None. Start immediately.
- **Parallel with.** Everything.
- **Eyra prod impact.** None.
- **Verification.** The pointers are in both `CLAUDE.md` files and the teams are briefed.
- **Rollback.** Not applicable.
- **Decisions/authorizations.** None.

### Step 1 — Remove dead code and retire Banking

- **Goal.** Carry no dead or retired code into either repository.
- **Scope.**
  - Delete dead code:
    - `core/systems/privacy`
    - `core/frameworks/selectical`
    - `core/lib/eyra_core.ex`
    - `core/lib/core/marks.ex`
    - the dead `Next.Desktop` references in [`core/systems/advert/view_model_builders.ex`](../../core/systems/advert/view_model_builders.ex)
    - the dead `Next.Assignment` reference in [`core/frameworks/green_light/loaders.ex`](../../core/frameworks/green_light/loaders.ex)
    - `core/priv/bundles/link` and the bundle `Plug.Static` in [`core/lib/core_web/endpoint.ex`](../../core/lib/core_web/endpoint.ex)
    - the stale `Systems.Questionnaire` grant in [`core/lib/core/authorization.ex`](../../core/lib/core/authorization.ex)
  - Merge the gettext domains with typos: `erya-support`, `eya-zircon`, `eyra.ui`.
  - **Banking:**
    - Remove `core/systems/banking` together with its supervisor in [`core/lib/core/application.ex`](../../core/lib/core/application.ex).
    - Remove `core/lib/banking_client*`.
    - Remove `config :core, BankingClient` and `:banking_backend` from [`core/config/config.exs`](../../core/config/config.exs).
    - Replace the `Banking.Public.is_live?` call in [`core/systems/fund/_public.ex`](../../core/systems/fund/_public.ex).
    - Remove [`banking_proxy/`](../../banking_proxy) and [`.github/workflows/banking_proxy_release.yml`](../../.github/workflows/banking_proxy_release.yml).
    - Put the `money_manager_transaction_marker` table on deferred drop.
- **Dependencies.** None.
- **Parallel with.** Step 0, step 2, track F.
- **Eyra prod impact.** None expected. Production uses `Systems.Banking.Dummy`, and the removed fetcher only polled the dummy. Ships in a regular milestone.
- **Verification.**
  - The full test suite passes.
  - Fund flows (pay-in, payout) work on staging.
  - Boot logs and `/.status/health` are clean.
- **Rollback.** Revert the PR. The table is dropped only in a later release.
- **Decisions/authorizations.** Deleting `banking_proxy/` from the repository.

### Step 2 — Early visible layout and the boundary check

- **Goal.** Make target ownership visible in the tree now and stop new coupling, while the code stays one Mix project.
- **Scope.**
  - **Move folders with `git mv`, inside `core/`.**
    - `core/mica/{lib,systems,frameworks}` gets everything Mica will own, including systems that are still entangled.
    - `core/next/{lib,systems}` gets everything Next will own:
      - `core/bundles/next`
      - the student, citizen, graphite, zircon, paper, annotation, ontology and onyx systems
      - `core/lib/mix/tasks/e2e.ex`
      - the Next fixtures of `core/frameworks/e2e`
    - `core/bundles/self` becomes Mica's reference SaaS under `core/mica/`.
  - **Follow-up changes:**
    - update `elixirc_paths` in [`core/mix.exs`](../../core/mix.exs) and [`core/.formatter.exs`](../../core/.formatter.exs)
    - update the Tailwind `content` globs in [`core/assets/tailwind.config.js`](../../core/assets/tailwind.config.js)
    - update the `COPY` lines in the [`Dockerfile`](../../Dockerfile) and [`core/Dockerfile`](../../core/Dockerfile)
    - update the bundle import in `config.exs`
  - **Boundary check in CI.** A credo custom check plus a `mix xref` script that:
    - fails when a module under `core/mica/**` references a module defined under `core/next/**`
    - fails on new PaNL, VU or Eyra literals under `core/mica/**`: `:panl`, `"Panl"`, `panl.nl`, `eyra.co`, `@eyra.service`, VU study codes
    - uses a committed allowlist of today's violations (about 90 files)
- **Dependencies.** Preferably after step 1.
- **Parallel with.** Step 0, step 1, track F.
- **Eyra prod impact.** None at runtime. The risk is breaking the build or deploy. Merge early in a milestone. The PR must build the Fly image, the AWS release tarball and both Docker images.
- **Verification.**
  - The release contains the same set of `.beam` modules as before.
  - The snapshots are green.
  - The boundary check reports the allowlist count.
- **Rollback.** Revert the move PR. Other open PRs need a rebase, so agree the merge moment with the Next team.
- **Decisions/authorizations.** A short merge freeze around the move PR.

> Why move folders now but create separate Mix projects only in step 8: a separate Mica project cannot compile while Mica code still references Next modules. Moving folders inside one project makes the boundary visible and enforceable from day one. Step 8 is then a second `git mv` plus two `mix.exs` files. `git log --follow` and blame survive both renames.

---

## Phase B — Decoupling (still one Mix project)

Steps 3 and 4 fix the contract, and steps 5–7 build on it. Once step 3 is merged, step 6 fans out into parallel PRs, one per item. Every step lowers the allowlist count.

### Step 3 — `Core.Extension` and open registries

- **Goal.** A SaaS, and each Mica system, can add routes, grants, handlers and so on without editing a central list.
- **Scope.**
  - **The `Core.Extension` behaviour.** It covers:
    - routes, grants, signal handlers, notifiers and notify channels
    - supervisor children, Oban queues and crons, rate quotas
    - seeds and the migrations path
    - feature flags (declared, default off)
    - admin panels and account features

    See [design.md §3.3](./design.md#33-the-coreextension-contract).
  - **Convert the extensions.** Each Mica system becomes a `Systems.X.Extension`; the Next bundle becomes `Next.Extension`.
  - **Replace the hand-maintained lists:**
    - [`core/systems/routes.ex`](../../core/systems/routes.ex)
    - the static grants in [`core/lib/core/authorization.ex`](../../core/lib/core/authorization.ex)
    - the `:signal` handler list and the `Systems.Notify` notifier list in [`core/config/config.exs`](../../core/config/config.exs)
    - [`core/lib/core/bundle_overrides.ex`](../../core/lib/core/bundle_overrides.ex)
    - the `core/.bundle.ex` selection; instead, the SaaS lists its extensions in config
  - **Oban crons.** Move them into extension declarations, keeping the environment toggles from `runtime.*.exs`.
  - **Feature flags.**
    - Declared flags default to *off*. [`core/lib/core/feature_flags.ex`](../../core/lib/core/feature_flags.ex) treats an unconfigured flag as on today.
    - Next declares its current defaults, so the flags in effect stay identical.
    - Check production's `ENABLED_APP_FEATURES` first.
  - **Prepare the OTP rename.** Add one accessor (for example `Core.Env.get/2`) and route the roughly 66 `Application.*env(:core, …)` calls through it.
- **Dependencies.** Step 2.
- **Parallel with.** Step 4, track F. The conversion can be split into several PRs after the behaviour PR.
- **Eyra prod impact.** None intended. Ships over one or two milestones.
- **Verification.**
  - The route, permission, handler and cron snapshots are identical.
  - `/.status/features` is identical on staging and production before and after.
- **Rollback.** Revert. No data changes.
- **Decisions/authorizations.** None.

### Step 3b — OTP app rename `:core` → `:mica`

- **Goal.** Do the decided rename while there is still one project, as a small PR.
- **Scope.**
  - Set `app: :mica` in `core/mix.exs`.
  - Rename `config :core, …` to `config :mica, …` in all config files.
  - Update the accessor.
  - Update the call sites that name the app: `otp_app: :core`, `app_dir(:core, …)`, `from: :core` (about 10).
  - Update the Gettext backend and the `priv` paths.
  - Keep the release binary name `core` for now (`releases: [core: …]`). [`core/scripts/predeploy`](../../core/scripts/predeploy), [`core/scripts/docker-start-app`](../../core/scripts/docker-start-app), the root `Dockerfile` entrypoint and Eyra's AWS deploy tooling (outside this repository) all call `bin/core`.
- **Dependencies.** The accessor from step 3.
- **Parallel with.** Steps 4–6.
- **Eyra prod impact.** Build-level only. Environment variable names do not change. Rehearse the release build and deploy on `eyra-next-dev` and staging, and run one AWS release build.
- **Verification.**
  - The app boots on dev and staging.
  - Smoke tests pass.
  - `predeploy` runs migrations and seeds.
- **Rollback.** Revert the PR.
- **Decisions/authorizations.** Whether the release binary stays `core` or becomes `next` (open question 3).

### Step 4 — Brand and config seams

- **Goal.** Mica code contains no Eyra or Next branding and no instance config, and Next reproduces today's output exactly.
- **Scope.**
  - **`Core.Brand` behaviour with a neutral Mica default.** `Next.Brand` provides:
    - name and logos
    - footer, now in [`core/frameworks/pixel/components/footer.ex`](../../core/frameworks/pixel/components/footer.ex) (the "Powered by Eyra" line becomes Next's choice)
    - policy URLs (`next_*` and `panl_*` in `core/config/config.exs`)
    - support email
    - email signature and "Next" wording in `core/systems/email/email/*.eex`
    - mail-from address
    - AppSignal name
    - invoice prefix and merchant/donation recipient name, from `core/systems/fund/_public.ex`
    - manifest and favicons
  - **Instance config moves to Next's config:** partner/pool logos (`:pixel, :pool_assets`), auth method lists, post-sign-in pages.
  - **Translations.**
    - Rename the `eyra-*` gettext domains to neutral names in one scripted PR.
    - Replace brand words in msgstrs with brand interpolation.
    - Give Next its own Gettext backend for the `eyra-next` and PaNL copy.
  - **De-brand Pixel:** the footer, the logo catalogue and the `__eyra_field_*` attributes.
- **Dependencies.** Step 3.
- **Parallel with.** Steps 5 and 6, track F. Schedule the gettext rename at a quiet moment, because it touches every `dgettext` call.
- **Eyra prod impact.** None visible.
- **Verification.**
  - Snapshot tests of every email template and of the app, workspace and website layouts for Next.
  - All 7 locales resolve.
  - On staging, manually check the sign-up email, the OTP email, the footer and the terms page.
- **Rollback.** Revert.
- **Decisions/authorizations.** Whether Mica shows "Powered by Mica / Nova" by default (open question 7).

### Step 5 — Open tool and item registry (data migration)

- **Goal.** Next, and later anyone, can add tools and project items without a Mica migration. This is required before Graphite and Zircon can live in Next.
- **Scope.**
  - **`Core.Tool` behaviour:** type, schema, prepare, form/view, director, export/import, icon/title.
  - **Registry references.**
    - Add `tool_type`/`tool_id` to `workflow_tool_refs` and `item_type`/`item_id` to `project_items`.
    - Backfill them from the per-tool foreign-key columns, which are defined today in [`core/systems/workflow/tool_ref_model.ex`](../../core/systems/workflow/tool_ref_model.ex) and [`core/systems/project/item_model.ex`](../../core/systems/project/item_model.ex).
    - Switch reads to the new columns, and put the old ones on deferred drop.
  - **Directors** become registry-validated strings instead of compile-time `Ecto.Enum` values.
  - **Assignment and Workflow** lose their hard-wired Zircon/Lab/Feldspar handling.
  - **`Workflow.Platforms`** moves to the Feldspar side.
- **Dependencies.** Step 3.
- **Parallel with.** Step 4, the parts of step 6 that don't touch tools, track F.
- **Eyra prod impact.** **A data migration on live tables**, in three releases:
  1. Add the columns, backfill and dual-write.
  2. Switch reads.
  3. Drop the old columns, at least one milestone later.

  Rehearse each release on a copy of production data and on staging.
- **Verification.**
  - Backfill counts match.
  - The integrity handling on tool delete is tested.
  - e2e passes for creating, running and exporting assignments with each tool type.
  - The setup export/import round-trip works.
- **Rollback.** For releases 1 and 2, revert the code; the old columns are still in sync. Release 3 happens only after a full milestone without issues.
- **Decisions/authorizations.** The user approves the data migration plan before release 1.

### Step 6 — Move instance specifics out of Mica (fan-out)

- **Goal.** Remove the remaining boundary violations, so Mica code uses only the contract.
- **Scope.** One PR series per item. Each moves code to `core/next/**` behind an extension point and lowers the allowlist.
  - **PaNL:**
    - the sign-up privacy flow and the `add_to_panl` post-action
    - `participant?(:panl)` checks in account features
    - the finished-view "Join Panl" call to action
    - the paid-slot PaNL policy and the questionnaire runtime config
    - the home marketplace block
    - project item gating and advert marks
    - `get_or_create_panl` and the `:panl` pool seed in [`core/lib/core/seeds/base.ex`](../../core/lib/core/seeds/base.ex)
    - the PaNL e2e fixtures
  - **VU:**
    - student codes and `generate_vu`
    - `VUDaySchedule`, which becomes Lab config supplied by Next
    - the student promotion next action
  - **Pool directors.** Citizen and Student register as pool directors from Next.
  - **Admin and Org.** The citizen/pool admin settings and the Org pools tab become panels contributed by Next through the extension contract.
  - **Home.** Mica gets a minimal default home. Next's current home moves to Next and is set through start pages.
  - **Eyra-domain synthetic accounts.** The `@eyra.service`, `external+…@eyra.co` and `@next.eyra.co` addresses become config with Next's values.
  - **External panel ids.** `liss` and `ioresearch` become Next config. Mica keeps `generic`.
  - **Integrations.** SURFconext and Centerdata auth, the OPP payment provider and Yoda storage move behind their behaviours. They go to `core/next/integrations` until their owner is decided (open question 5). Only Nova-governed code goes into Mica; they can graduate later.
  - **Graphite and Zircon** (with Paper, Annotation, Ontology, Onyx):
    - depend only on `Core.Tool` and `Core.Extension`
    - the screening agent concept moves with Zircon
    - the Paper registry moves from `Core.Application` into Zircon's extension children
  - **Remaining dependency cycles** are broken with signals or behaviours where the direction would otherwise be Mica → Next:
    - Account ↔ Fund/Payment
    - Assignment ↔ Pool/Advert
    - Fund ↔ Advert/Pool
- **Dependencies.** Step 3. Graphite and Zircon also need step 5.
- **Parallel with.** Most items run in parallel, each with its own Flux issue and worktree. Coordinate with ongoing Next feature work in the same systems.
- **Eyra prod impact.** None visible per PR. Ships continuously over several milestones.
- **Verification.**
  - The allowlist shrinks with every PR, and the snapshots are unchanged.
  - The PaNL journeys stay green in e2e: sign-up with PaNL consent, finished-view call to action, marketplace.
  - The student and citizen pool flows work on staging.
- **Rollback.** Revert per PR.
- **Decisions/authorizations.** Ownership of the integrations (open question 5).
- **Done when:**
  - the allowlist is empty
  - `core/mica/**` compiles without `core/next/**` (a CI job does exactly this)

### Step 7 — Table ownership and migration paths

- **Goal.** Every table has one owner, migrations live with that owner, and foreign keys point only from the SaaS to Mica.
- **Scope.**
  - **Ownership manifest:** each table mapped to its owner, generated from the Ecto schemas in each folder and checked in CI.
  - **CI check:** no foreign key from a Mica table to a Next table. Fix any violations found; step 5 resolves most of them.
  - **Split the migrations.** Divide `core/priv/repo/migrations` into a Mica path and a Next path by owner. Filenames and versions stay unchanged.
  - **Run both paths.** `Core.Release.migrate/0` and `mix ecto.migrate` run the Mica path plus the extension paths.
  - **Mixed migrations.** Historical migrations that touch both owners stay in Mica's path until the squash in step 9.
  - **Seeds** are declared per extension.
- **Dependencies.** Steps 5 and 6.
- **Parallel with.** Rest of step 4, track F, step 9 (part A).
- **Eyra prod impact.** None. These are the same migration versions, already applied.
- **Verification.**
  - A fresh database built from both paths matches today's [`core/priv/repo/structure.sql`](../../core/priv/repo/structure.sql).
  - On a production snapshot, nothing is pending.
- **Rollback.** Revert the file moves.
- **Decisions/authorizations.** None.

---

## Phase C — Split and cutover

### Step 8 — Layout split: `mica/` and `next/` as two Mix projects

- **Goal.** Two real Mix projects in this repository, with `core/` gone. This is the shape the repositories will have.
- **Scope.**
  - **`git mv core/mica mica/`.** This is the Mix project `:mica`, with its own `mix.exs`, `priv`, gettext, neutral static assets and the reference SaaS (Self).
  - **`git mv core/next next/`.** This is the Phoenix app `:next`, with `{:mica, path: "../mica"}`. Next owns:
    - endpoint and router composition
    - config, including `runtime.fly.exs` and `runtime.aws.exs`
    - `rel/`, the Dockerfile, `fly.*.toml` and the scripts
    - `assets/`, which imports Mica's JS hooks and adds Mica to the Tailwind content
    - the e2e, smoke and load tests
  - **Mica keeps its own tests.** They run against the reference SaaS.
  - **Workflows.**
    - Update `release.yml`, `docker_release.yml`, `fly-deploy-*.yml` and `e2e*.yml` to build from `next/`.
    - Add a Mica CI job that builds and tests `mica/` on its own.
    - The `BUNDLE` build argument disappears.
  - **Self.** Self deployments keep building from a pinned pre-step-8 tag of this repository, unless the reference SaaS is made deployable for them first (open question 2).
- **Dependencies.** Steps 3–7: the allowlist is empty and the standalone compile job is green.
- **Parallel with.** Step 9, track F.
- **Eyra prod impact.** The build and release pipeline changes; runtime behaviour must not. Rollout:
  1. Rehearse on a branch. Build the Fly image and the AWS tarball from `next/`, deploy to `eyra-next-dev`, and run e2e and smoke tests.
  2. Merge at the start of a milestone.
  3. Run the full e2e on staging.
  4. Ship to production through the normal AWS release flow. The binary name is unchanged.
- **Verification.**
  - The release diff shows the same modules (now across `:mica` and `:next`), the same migration versions and the same route and permission snapshots.
  - Smoke tests pass on production after the release.
- **Rollback.** Redeploy the previous release artifact. Reverting the move itself is possible but heavy.
- **Decisions/authorizations.** The merge moment, agreed with the Next team. The user decides the Self strategy.

### Step 9 — Pre-transfer assessment and migration baselines

- **Goal.** Know exactly what becomes public or accessible under `novasoftwarefoundation`, and prepare the database baselines.
- **Part A: assessment.** A read-only report covering:
  - **Content of `mica/`:**
    - a secrets scan of the tree (for example gitleaks)
    - Eyra-private material: customer names, internal hosts, fixtures with real e-mail domains
    - docs and agent instructions that describe Eyra infrastructure
  - **History.** Mica starts with fresh history, so only the tree is published. Confirm that pointing the first commit back to `eyra/mono`, which stays public, is acceptable.
  - **Licence.** This repository and `eyra/feldspar` are AGPL-3.0 ([`COPYING.md`](../../COPYING.md)). Two questions need legal input, not an engineering answer:
    - the copyright holder and notices under Nova, and a contributor agreement for non-Eyra contributors
    - the consequences for operators, including for `eyra/next`
  - **Dependencies.** Mica would rely on these Eyra-owned forks: `bamboo_phoenix`, `bamboo_ses`, `live_nest`, `packmatic`. `@novasoftwarefoundation/prism` already belongs to Nova.
  - **GitHub setup:**
    - org access, teams and branch protection
    - Actions secrets for Mica CI (no Eyra production secrets)
    - Renovate
    - the docs site ([`docs.yml`](../../.github/workflows/docs.yml))
    - the [`SECURITY.md`](../../SECURITY.md) contact
- **Part B: baselines.**
  - Generate a Mica baseline and a Next baseline migration.
  - Write the script that inserts their versions into `schema_migrations`.
  - Dry run on a restored production snapshot in an isolated environment:
    - nothing is pending
    - the schema dump is unchanged
    - a fresh database built from the baselines matches production's schema
  - Also test the rollback script, which deletes the inserted rows.
- **Dependencies.** Part A can start after step 2 and is re-run on the final tree before step 10. Part B needs step 7.
- **Parallel with.** Step 8, track F.
- **Eyra prod impact.** None. The snapshot contains personal data, so handle it with the same controls as backups.
- **Verification.** The user reviews the report. The dry-run evidence (schema diffs, pending-migrations output) goes on the Flux issue.
- **Rollback.** Not applicable.
- **Decisions/authorizations.**
  - Using a production snapshot.
  - Accepting the assessment, including the licence answer, before step 10.

### Step 10 — Create the repositories

- **Goal.** `novasoftwarefoundation/mica` and `eyra/next` exist and build. `eyra/mono` remains the source of truth until step 11.
- **Scope.**
  - **`novasoftwarefoundation/mica`:**
    - fresh history; the first commit is `mica/` at `eyra/mono` commit X, with a message pointing to `eyra/mono@X`
    - the Mica baseline, CI and branch protection
    - tag `v0.1.0`
  - **`eyra/next`:**
    - built from `next/` plus the root files Eyra needs
    - history approach is open question 4
    - `{:mica, github: "novasoftwarefoundation/mica", tag: "v0.1.0"}`
    - the Next baseline, workflows and Fly config; secrets are re-created in the new repository
  - **Sync window.** Changes on `eyra/mono` after X are replayed, or development pauses briefly. Keep the window to days.
- **Dependencies.** Steps 8 and 9.
- **Parallel with.** Track F.
- **Eyra prod impact.** None yet. `eyra/next` deploys only to `eyra-next-dev`.
- **Verification.**
  - Mica CI is green on its own.
  - `eyra/next` builds the same release as `eyra/mono@X`.
  - Full e2e passes on dev.
- **Rollback.** Archive the new repositories. Nothing depends on them yet.
- **Decisions/authorizations.**
  - **The user authorizes creating `novasoftwarefoundation/mica` (public) and `eyra/next`.**
  - The user decides who gets admin rights on the Nova repository.

### Step 11 — Cutover of Eyra production to `eyra/next`

- **Goal.** Eyra's production Next is built and released from `eyra/next`, with Mica as a tagged dependency.
- **Migration plan.**
  1. Freeze Next development on `eyra/mono`, do the final sync, and tag it `pre-split-final`.
  2. Deploy `eyra/next` to staging and run the full e2e.
  3. In a maintenance window on production:
     - take a backup
     - run the baseline-marking script (rehearsed in step 9)
     - deploy the `eyra/next` release through the normal AWS flow
     - run `predeploy`; nothing should be pending
     - run the smoke tests
  4. Point the Fly dev/staging workflows and the AWS release source at `eyra/next`, and disable the Next workflows in `eyra/mono`.
  5. Monitor AppSignal and the job queues for one milestone.
- **Rollback plan.**
  - Before the baseline marking: abort and keep `eyra/mono`.
  - After the marking: the marking only *adds* `schema_migrations` rows, so the previous `eyra/mono` release still runs. Redeploy it, and if needed remove the inserted rows with the tested script.
  - The cutover release contains no destructive schema change.
- **Dependencies.** Step 10 is verified.
- **Parallel with.** Track F, but not the Feldspar transfer in the same window.
- **Eyra prod impact.** One planned release with a short maintenance window.
- **Verification.**
  - Smoke and e2e pass on production, and nothing is pending.
  - AppSignal error rates are unchanged for 48 hours.
  - Data donation delivery, payment webhooks and reconciliation all work.
- **Decisions/authorizations.**
  - **The user authorizes the cutover and the maintenance window.**
  - The user decides the status of `eyra/mono` afterwards (open question 1).

---

## Track F — Feldspar (summary)

Full plan: [eyra/feldspar `doc/nova-migration/plan.md`](https://github.com/eyra/feldspar/blob/develop/doc/nova-migration/plan.md). Tracked in the Feldspar Flux project.

- **F1 — Mica App Protocol v1.**
  - Write down the current postMessage/MessagePort and HTTP protocol as a versioned spec in Mica's docs.
  - Add a backward-compatible version handshake.
  - Tighten the origin checks on both sides.
  - The host side lives in [`core/assets/js/feldspar_app.js`](../../core/assets/js/feldspar_app.js) and [`core/systems/feldspar`](../../core/systems/feldspar).
  - Can start now.
- **F2 — Contract tests.** Shared fixtures run in both CIs.
- **F3 — Transfer `eyra/feldspar` to `novasoftwarefoundation/feldspar`.**
  - It is a GitHub transfer, so the full history moves. It needs its own pre-transfer assessment and the user's authorization.
  - After the transfer, update the Feldspar release URL in `core/frameworks/e2e/controller.ex`.
  - Not in the same window as step 11.

## Order at a glance

```
Step 0 ─┬─ Step 1 ─── Step 2 ── Step 3 ─┬─ Step 3b
        │                               ├─ Step 4
        │                               ├─ Step 5 ──┐
        │                               └─ Step 6 ──┴─ Step 7 ── Step 8 ── Step 10 ── Step 11
        │            Step 9A (after 2, final run before 10) ──────────────┘
        │            Step 9B (after 7) ───────────────────────────────────┘
        └─ Track F: F1 ── F2 ── F3 (own assessment; not in the step 11 window)
```

- **Can start now:** steps 0, 1 and F1.
- **Can run in parallel after step 3:** steps 4, 5 and the items of step 6.
- **Strictly sequential:** 2 → 3, then 7 → 8 → 10 → 11.

## Open questions

1. **`eyra/mono` after the split.** Read-only/archived, or security fixes for the Self deployments that use it? If fixes: who backports them, and for how long? Should Self move to Mica's reference SaaS (or `novasoftwarefoundation/mica-saas`) instead, and when?
2. **Self during step 8.** Do Self deployments pin to a pre-split tag, or must the reference SaaS be deployable for them first?
3. **Release binary name.** Keep `bin/core` through the cutover, or rename to `next`? Renaming requires changing Eyra's AWS deploy tooling.
4. **`eyra/next` history.** Fresh start with a pointer (like Mica), or filtered full history?
5. **Integrations** (OPP, Yoda, SURFconext, Centerdata). Mica building blocks under Nova governance, separate Nova-owned packages, or Next?
6. **Generic cloud backends** (S3/Tigris, Azure storage, Mailgun/SES). Mica core or integration packages?
7. **"Powered by Mica / Nova".** A default in Mica's brand, configurable, or nothing?
8. **Eyra-owned forks** used as Mica dependencies (`bamboo_phoenix`, `bamboo_ses`, `live_nest`, `packmatic`). Move them to Nova, upstream them, or keep them as Eyra-maintained?
9. **Licence and copyright.** Copyright holder for Mica and Feldspar after the move, and the AGPL-3.0 consequences for operators. This needs legal input.
10. **Translation overrides.** Do SaaS repositories need to override Mica's UI copy?

<sub>Written by an AI agent (Claude Code · Claude Opus 5.5, herdr-projects nova-migration · t-0001).</sub>
