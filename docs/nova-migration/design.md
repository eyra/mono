# Mica and Next: design of the split

Status: **design approved in outline (Option A); details and open questions below.** The step-by-step execution is in [plan.md](./plan.md).

Paths are relative to the repository root and describe the layout of `develop` at 3b560a9c0 (2026-10-11), before the migration. Since step 2, `core/X` means `core/mica/X`, `core/next/X` or `core/mica_saas/X`; see the step 2 section of [plan.md](./plan.md).

## Contents

0. [Summary](#0-summary)
1. [Decisions](#decisions)
2. [Current state: how bundles work today](#1-current-state)
3. [Inventory: who owns what](#2-inventory)
4. [Target design](#3-target-design)
5. [Open questions](#4-open-questions)

---

## 0. Summary

- **What `core/` becomes.** It is split into two parts:
  - **Mica** goes to `novasoftwarefoundation/mica`. It is the generic, Nova-governed foundation for building a SaaS: "a collaboration and service integration hub that makes it possible to launch robust, mature and commercially viable scientific tools from the get go". Mica is service agnostic and is not itself hosted.
  - **Next** goes to `eyra/next`. It is the SaaS that Eyra builds on Mica and hosts.
- **Today's bundle is the wrong boundary.** A bundle is a compile-time switch that selects `core/bundles/next` or `core/bundles/self`. That only covers sign-in routes, a few grants, menus, start pages, a title and feature-flag defaults. Almost all Eyra- and Next-specific code lives *outside* `core/bundles/`.
- **The composition is inverted.** Today core is the root application and picks a bundle. In the target, **the SaaS is the root project and Mica is a dependency**. The SaaS plugs in through an explicit extension contract, `Core.Extension`. Mica's own systems use the same contract.
- **Most of the work is decoupling inside this repository.** The repository split happens late and is mechanical once the dependency direction is clean. See [plan.md](./plan.md).

---

## Decisions

Made by the product owner on 2026-10-11/12 and recorded on Flux Next issue 10395322806.

| # | Topic | Decision |
|---|---|---|
| D1 | Packaging | **Option A.** The SaaS (`eyra/next`) is the root Phoenix project. Mica is a versioned Mix dependency (`{:mica, …}`). Mica provides the router, authorization, endpoint building blocks, supervisor children, migrations, JS hooks and the `Core.Extension` contract. Mica's own systems are extensions on the same contract. During the migration Next may use a `path:` or branch dependency; afterwards it pins to tags. Options B and C are not pursued (see [§3.2](#32-packaging-options)). |
| D2 | Governance | Mica contains only code under Nova governance. |
| D3 | Graduation | Custom or experimental systems and frameworks live in the SaaS repository on Mica's extension contract (`Core.Extension`/`Core.Tool`). Mature, generic ones can move into Mica later as optional building blocks, under Mica's stability promise and Nova governance. Quick third-party experiments use Feldspar. |
| D4 | Graphite, Zircon | Graphite and Zircon, together with Paper, Annotation, Ontology and Onyx, start outside Mica, in Next. They are the proof that the extension contract works. |
| D5 | Recruitment and rewards | Pool, advert and promotion (the recruitment machinery behind PaNL), together with assignment, fund and affiliate, go to Mica as **optional building blocks**. Instance specifics move to the SaaS: the PaNL name, panl.nl terms and privacy URLs, seeds such as the always-created `:panl` pool, hard-coded `participant?(:panl, …)` checks, and VU student codes. |
| D6 | Banking proxy | `banking_proxy` is not deployed anywhere. It is retired, not ported. |
| D7 | Names | The Elixir modules keep `Core.*`/`CoreWeb.*`. The OTP app is renamed from `:core` to `:mica` as part of the decoupling steps, not as a separate big-bang change. |
| D8 | Database | One database per deployment. Every table has one owner (Mica or the SaaS), with migrations in the owner's repository. Foreign keys point only from the SaaS to Mica. `workflow_tool_refs` and `project_items` become open registry references. Historical migrations are squashed into a Mica baseline and a SaaS baseline, which are marked as applied in Eyra production after a dry run on a production snapshot. Separate Postgres schemas per owner remain an option for later. |
| D9 | History | `novasoftwarefoundation/mica` starts with fresh git history. Its first commit points back to the `eyra/mono` commit it came from. `eyra/mono` is not deleted; Self deployments use it. |
| D10 | Approach | Incremental, inside `eyra/mono` `develop`, in normal small PRs shipped through Next's milestones. No big-bang migration and no copy of core. Guardrails: an early visible layout, a CI boundary check that blocks Mica → Next references and new `:panl` hard-coding, and the rules communicated to the Next and Feldspar teams. |
| D11 | Layout | `core/` is split with `git mv` into `mica/` (Mix project) and `next/` (Phoenix app with `{:mica, path: "../mica"}`). `core/` disappears. Self is the reference SaaS on Mica, a sibling of Next and not part of Mica: since step 2 it lives in `core/mica_saas/` (decided 2026-10-14). It may later get its own repository, `novasoftwarefoundation/mica-saas` (deferred). |
| D12 | Repositories | `mica/` → `novasoftwarefoundation/mica`; `next/` → `eyra/next`; `eyra/feldspar` → `novasoftwarefoundation/feldspar` (Feldspar Flux project). The Mica–Feldspar protocol becomes a versioned public contract. Prism already lives at `novasoftwarefoundation/prism`. |
| D13 | Deployment model | One SaaS per deployment. Each operator builds and runs its own SaaS on Mica; multi-tenancy is out of scope. |

---

## 1. Current state

### 1.1 How a bundle is selected (compile time)

1. [`core/.bundle.ex`](../../core/.bundle.ex) defines `Bundle.name/0`. It reads the `BUNDLE` environment variable, then a `.bundle` file (none exists), and defaults to `next`.
2. [`core/config/config.exs`](../../core/config/config.exs) (around lines 264–280) compiles `.bundle.ex` and sets `config :core, :bundle`. It then imports `../bundles/#{bundle}/config/config.exs`. [`core/config/test.exs`](../../core/config/test.exs) forces `:next` *after* that import.
3. `elixirc_paths` in [`core/mix.exs`](../../core/mix.exs) always includes `bundles`. **Both bundles are always compiled; only the selected one is wired in.**
4. Several places are fixed at compile time:
   - [`core/lib/core/bundle_overrides.ex`](../../core/lib/core/bundle_overrides.ex) builds the module name `"#{Capitalized}.Bundle"`. It splices that module's `routes/0` into [`core/lib/core_web/router.ex`](../../core/lib/core_web/router.ex) and its `grants/0` into [`core/lib/core/authorization.ex`](../../core/lib/core/authorization.ex).
   - [`core/lib/core_web/endpoint.ex`](../../core/lib/core_web/endpoint.ex) serves static files from `priv/bundles/<bundle>`. Only a stale `priv/bundles/link` exists, so for `next` and `self` this serves nothing.
   - The `:pixel, :pool_assets` and `:policy_urls` settings are read with `compile_env`.
5. **One build serves one bundle.** These all pass `BUNDLE` (default `next`) or hard-code it:
   - [`.github/workflows/release.yml`](../../.github/workflows/release.yml) (input `bundle`, default `next`)
   - [`docker_release.yml`](../../.github/workflows/docker_release.yml)
   - `core/fly.*.toml`
   - the root [`Dockerfile`](../../Dockerfile)
   - `mix github_release`

### 1.2 What a bundle contributes

| Concern | Mechanism | Next bundle |
|---|---|---|
| Routes | `Next.Bundle.routes/0`, spliced in first so it overrides core routes | `/.well-known/apple-app-site-association`, `/user/signin[/:type]`, `/user/auth/{identify,verify,redeem,status,:provider}`, `/user/session` |
| Grants | `Next.Bundle.grants/0` | 4 pages |
| Start pages | `config :core, start_pages:` → `CoreWeb.StartPageProvider` | `/` (member), `/project` (creator) |
| Menus | `config :core, menu_items:` (`CoreWeb.Menu.ItemsProvider`) and `*_menu_builder:` (`CoreWeb.Menu.Builder`) | items plus three builders |
| Title | `config :core, :meta, bundle_title:` → `CoreWeb.Meta` (default `"Eyra"`) | `"Next"` |
| Post-sign-in pages | `config :core, Systems.Account.UserAuth` | `/project`, `/` |
| Feature-flag defaults | `config :core, :features`, merged at runtime with `ENABLED_APP_FEATURES` | 12 flags, including `panl`, `onyx`, `leaderboard`, `surfconext_sign_in` |
| Auth methods, pool logos | `:account, :auth_methods`; `:pixel, :pool_assets` | surfconext, centerdata, google, email; panl logos |
| Translations | No per-bundle `.po` files. `start_page_translations.ex` only makes `gettext.extract` see the `start.page.*` keys. | — |
| Static files, migrations, Oban, signal handlers | None per bundle | — |

[`core/lib/core/feature_flags.ex`](../../core/lib/core/feature_flags.ex) treats an **unconfigured flag as enabled**. A library must not do that.

### 1.3 Central registries a new system must edit today

| Registry | Where |
|---|---|
| System routes | [`core/systems/routes.ex`](../../core/systems/routes.ex): a literal list of 22 systems |
| Page grants | [`core/lib/core/authorization.ex`](../../core/lib/core/authorization.ex): about 51 `grant_access` lines |
| Signal handlers, notifiers | [`core/config/config.exs`](../../core/config/config.exs) |
| Notify channels | [`core/systems/notify/dispatcher.ex`](../../core/systems/notify/dispatcher.ex) |
| Tool types | [`core/systems/workflow/tool_ref_model.ex`](../../core/systems/workflow/tool_ref_model.ex): one foreign-key column per tool. Also `core/systems/workflow/_public.ex` |
| Project item types | [`core/systems/project/item_model.ex`](../../core/systems/project/item_model.ex): foreign keys to advert and the Graphite leaderboard |
| Tool directors | `config :core, tool_directors:`, used as compile-time `Ecto.Enum` values |
| JS hooks | [`core/assets/js/app.js`](../../core/assets/js/app.js) |
| Oban crons | `core/config/runtime.fly.exs`, `core/config/runtime.aws.exs` |
| Supervision tree | [`core/lib/core/application.ex`](../../core/lib/core/application.ex): starts Banking and the Paper registry unconditionally |
| Namespace resolution | [`core/frameworks/utility/module.ex`](../../core/frameworks/utility/module.ex): hard-codes `Next`, `Self`, `Systems` |
| Seeds | [`core/lib/core/seeds/base.ex`](../../core/lib/core/seeds/base.ex): seeds the PaNL pool in every environment |
| Migrations | `core/priv/repo/migrations`: 187 files in one directory |

### 1.4 Eyra- and Next-specific code outside `core/bundles/`

- **Branding:**
  - the footer with policy links and "Powered by Eyra" ([`core/frameworks/pixel/components/footer.ex`](../../core/frameworks/pixel/components/footer.ex))
  - the app layout, and `CoreWeb.Meta` defaulting to "Eyra"
  - `:policy_urls` (`next_*`, `panl_*`)
  - email templates ("Welcome to Next", "The Eyra team") in `core/systems/email/email/`
  - the home page links to eyra.co
  - the Next logo for builtin storage
  - the "Eyra's own product family" logo catalogue
  - `manifest.json`
  - `platform: "Next"` and the `NEXT-` invoice prefix in fund
  - `support@eyra.co` in code and in about 40 translations
  - AppSignal name "Next"
- **Hosting and release:**
  - `core/fly.*.toml` (`eyra-next-*`)
  - the runtime configs (eyra.dev mail-domain fallback, Centerdata/SURFconext defaults, `STORAGE_SERVICES` default including Yoda)
  - the workflows
  - the e2e, smoke and load test hosts
  - the mix aliases
  - forked dependencies under `github.com/eyra`
- **Next service logic:**
  - PaNL in Pool, Account (sign-up, features, payouts), Assignment (finished view, paid slots, questionnaire runtime config), Home, Project and Advert, plus the PaNL seed
  - VU in Student and in Lab (`VUDaySchedule`)
  - Eyra as merchant and donation recipient in Fund and Payment
  - Eyra-domain synthetic accounts in Account and Affiliate
- **Customer-specific integrations:**
  - SURFconext and Centerdata/LISS sign-in, with routes compiled into every build in `core/lib/core_web/router.ex`
  - OPP payments
  - Yoda storage
  - the `liss`/`ioresearch` external panel ids
  - Bunq via `banking_proxy`
- **Generic code that only carries an Eyra or Next name:**
  - about 52 `eyra-*` gettext domains
  - the `__eyra_field_*` DOM attributes
  - the empty `Eyra.Core` module
  - dead references to the non-existent `Next.Desktop` and `Next.Assignment`

**Conclusion:** `core/bundles/next` holds only about 5% of what moves to `eyra/next`. The rest is interleaved with generic systems and has to be refactored before the boundary exists.

---

## 2. Inventory

Classes:
- **M**: Mica core
- **M-opt**: optional Mica building block
- **SaaS**: lives in the SaaS (Next), possibly graduating later (D3)
- **retire**: removed

"Blocker" names the coupling that has to go before the class holds.

### 2.1 Systems (`core/systems/*`)

| System | Class | Blocker / note |
|---|---|---|
| account | M | PaNL sign-up and privacy flow; `participant?(:panl)` checks; student codes; the student promotion next action; OPP-specific payouts and phone forms. Google/Apple sign-in becomes M-opt. SURFconext/Centerdata are integrations (open question 1). Next's email-first sign-in pages move *down* into Mica as the default. |
| admin | M | Citizen/Pool/Advert/Feldspar settings become admin panels contributed by extensions. |
| content, email, notify, next_action, observatory, monitor, rate, org, support, desktop, crew, consent, userflow, version | M | email: brand slots. notify: open channels, and remove the Assignment payloads. org: the pool tab becomes contributed. rate: quota names come from extensions. `next_action` is "next best action", not the brand. |
| project | M | The item foreign keys to advert and the Graphite leaderboard become the open item registry (D8). |
| workflow | M | The tool registry. Its closed, foreign-key-per-tool `tool_refs` becomes open (D8). |
| storage | M (builtin, S3, Azure) | The `:centerdata` branch and the Next logo. The node-local delivery queue (§3.9). Yoda is an integration (open question 1). |
| feldspar | M | The host runtime for sandboxed third-party apps, which is Mica's extension bridge. The upload context is assignment-specific, the storage endpoint lookup goes through Project, and `Workflow.Platforms` belongs to the Feldspar side. |
| assignment | M-opt (D5) | The most entangled system: PaNL finished view, paid slots, questionnaire config; `liss`/`ioresearch`; a direct `has_many :adverts`; hard-wired Zircon/Lab/Feldspar handling. |
| pool, advert, promotion | M-opt (D5) | PaNL is hard-coded throughout. It becomes SaaS config, seeds and a pool director. |
| fund | M-opt (D5) | Advert/Pool/Banking dependencies; `platform: "Next"`; the `NEXT-` prefix; Eyra as donation recipient (via `Core.Brand`). |
| affiliate | M-opt (D5) | The `@next.eyra.co` synthetic email domain becomes config. |
| bookkeeping | M-opt | Double-entry ledger. |
| payment | M-opt (behaviour) | `Systems.Payment.Provider` is the contract. OPP is an integration (open question 1). |
| alliance, document, instruction, manual | M-opt | Generic tools. |
| lab | M-opt | `VUDaySchedule` becomes config supplied by the SaaS. |
| citizen, student | SaaS | PaNL and VU pool directors. |
| home | SaaS (plus a minimal default in M) | Next's home, with PaNL blocks and eyra.co links. |
| graphite | SaaS (D4) | Benchmark challenge tool, on `Core.Tool`. |
| zircon, paper, annotation, ontology, onyx | SaaS (D4) | Literature screening and its knowledge-graph layer. `frameworks/concept/screening_agent.ex` moves with it. |
| banking | retire (D6) | Production always uses `Systems.Banking.Dummy`. |
| privacy | retire | Empty stub. |
| test | M (dev/test only) | |

### 2.2 Frameworks (`core/frameworks/*`)

| Framework | Class | Note |
|---|---|---|
| signal, green_light, fabric, utility, concept, user_state, builder | M | `fabric` is deprecated in favour of LiveNest. `utility/module.ex` must stop naming bundle namespaces. |
| pixel | M | The Elixir side of Prism. De-brand the footer, the logo catalogue and `__eyra_field_*`. |
| user_check | M-opt | Third-party email validation. |
| e2e | M mechanism, SaaS fixtures | |
| selectical | retire | Contains only a swagger file. |

### 2.3 `core/lib`

| Module | Class | Note |
|---|---|---|
| `core.ex`, `core/*` | M | Remove from `authorization.ex` the grants for SaaS systems; from `application.ex` the Banking and Paper children; from `seeds/base.ex` the PaNL seed; from `release.ex` the `@eyra.co` test user. |
| `core/image_catalog` | M-opt | Unsplash. |
| `core_web/*` | M | Router (SURFconext/Centerdata routes), endpoint (Feldspar plug, a dev token in source), loaders (Advert/Promotion), Meta and layout branding. |
| `core/marks.ex`, `eyra_core.ex` | retire | No callers. |
| `banking_client*` | retire (D6) | |
| `mix/tasks/e2e.ex` | SaaS | Eyra hosts. |

### 2.4 Boundary violations to fix

1. **Assignment** → Advert, Pool, PaNL, Zircon, Lab, Feldspar.
2. **Workflow and Project** → concrete tool and item schemas (closed registries enforced by foreign keys).
3. **Account, Admin, Org** → Pool, Student, Citizen. About 90 files reference these.
4. **`core/lib`** → SaaS systems: grants, supervision, endpoint plug, loaders, auth routes, seed.
5. **Fund** → Advert, Pool, Banking.
6. **Cycles:**
   - Account ↔ Fund/Payment
   - Assignment ↔ Pool/Advert
   - Assignment ↔ Workflow ↔ tools
   - Fund ↔ Advert/Pool
   - Project ↔ Assignment/Advert/Graphite

   Signals already exist to break these. The architecture rules in [`core/.cursor/rules/framework-signal.mdc`](../../core/.cursor/rules/framework-signal.mdc) forbid direct calls between systems, but the code does not follow that rule today.

---

## 3. Target design

### 3.1 Principles

1. **Dependency direction** is SaaS → Mica, never the reverse. Mica compiles, tests and boots on its own with its reference SaaS.
2. **The SaaS is the root application.** Mica provides building blocks, macros and behaviours. Mica never names a SaaS module.
3. **Open registries.** Every list in [§1.3](#13-central-registries-a-new-system-must-edit-today) becomes something extensions contribute to.
4. **Safe defaults.** Unknown feature flags are off. Mica ships neutral defaults for branding, home, sign-in and policy pages.
5. **Versioned public contracts.** `Core.Extension`, `Core.Tool`, `Core.Brand`, the integration behaviours and the Mica App Protocol are documented, semver'd and covered by contract tests.
6. **Names.**
   - Mica keeps `Core`, `CoreWeb`, `Systems` and `Frameworks` (D7).
   - SaaS code uses its own top-level namespace (`Next.*`) to avoid module collisions across packages. Systems that move to Next are renamed accordingly; Mica's modules are not.

### 3.2 Packaging options

| Option | Shape | Outcome |
|---|---|---|
| **A** | The SaaS is the root Mix project; Mica is a dependency (git tag first, Hex later) with extension macros and behaviours. | **Approved (D1).** True separation. Mica is versioned and testable on its own. Every operator repeats the same pattern. Cost: the biggest refactor up front. |
| B | Mica stays the root; the SaaS is a plugin dependency picked at build time (today's bundle, generalized). | Not pursued. The Mica repository would need to know about private SaaS repositories, and operators would not own their release pipeline. |
| C | Umbrella with Mica vendored (subtree/submodule) inside `eyra/next`. | Not pursued. Drifts into a fork, and the Mica version is implicit. |

Target shape of `eyra/next`:

```
eyra/next (Phoenix project, OTP app :next)
├── mix.exs           deps: {:mica, github: "novasoftwarefoundation/mica", tag: "v…"} (path: during migration)
├── lib/next/…        Next.Router (use CoreWeb.Router), Next.Extension, Next.Brand
├── lib/next/systems  pool directors (citizen, student), home, graphite, zircon, …
├── config/           Eyra config, feature flags, hosts, runtime.aws.exs / runtime.fly.exs
├── priv/repo/migrations, priv/gettext, priv/static (logos, favicons, manifest)
├── assets/           app.js imports Mica hooks + Next hooks; Tailwind preset = Prism + Next theme
└── rel/, Dockerfile, fly.*.toml, .github/workflows
```

### 3.3 The `Core.Extension` contract

```elixir
defmodule Core.Extension do
  @callback id() :: atom()
  # Composition (compile time, read by Mica macros)
  @callback routes() :: Macro.t()
  @callback grants() :: [{module(), [role]}]
  @callback signal_handlers() :: [module()]
  @callback notifiers() :: [module()]
  @callback notify_channels() :: %{atom() => module()}
  @callback tools() :: [module()]           # Core.Tool implementations (§3.4)
  @callback project_items() :: [module()]
  @callback pool_directors() :: [module()]
  @callback admin_panels() :: [module()]
  @callback account_features() :: [module()]
  # Runtime
  @callback children(opts) :: [Supervisor.child_spec()]
  @callback oban_queues() :: keyword()
  @callback oban_crons() :: list()
  @callback rate_quotas() :: list()
  @callback migrations_path() :: Path.t() | nil
  @callback seeds(env :: atom()) :: :ok
  @callback feature_flags() :: keyword()    # declared flags with safe defaults
  # all optional; `use Core.Extension` provides defaults
end
```

- **How the SaaS composes.** The SaaS lists its extensions with `config :mica, extensions: […]`. The router and authorization macros read that list at compile time, as `Core.BundleOverrides` does today. There is no runtime cost, and verified routes keep working.
- **Mica's systems are extensions too.** Each one (Assignment, Feldspar, Manual, …) is a `Systems.X.Extension` in Mica's default list.
- **SaaS-level behaviours.** The existing `CoreWeb.StartPageProvider`, `CoreWeb.Menu.ItemsProvider` and `CoreWeb.Menu.Builder` stay, and the new `Core.Brand` (§3.6) joins them.
- **Reference SaaS.** Mica keeps a small reference SaaS (Self) for its CI, its e2e tests and as operator documentation.

### 3.4 Tool and item registry

- **`Core.Tool` behaviour:**
  - `type/0`, `schema/0`, `prepare/1`
  - form and view
  - director support
  - export/import
  - icon and title
- **Polymorphic references.** `workflow_tool_refs` gets `tool_type`/`tool_id` and `project_items` gets `item_type`/`item_id`, each with an index. They replace one nullable foreign key per tool type.
- **Integrity.** Database-level referential integrity is replaced by signal-driven cleanup when a tool is deleted. This is the price of an open registry, accepted in D8.
- **Migration path.** Backfill the new columns from the existing foreign keys, and drop the old columns later using the deferred-drop pattern.
- **Directors** become strings validated against the registry, instead of a compile-time `Ecto.Enum`.

### 3.5 Config, migrations, translations, assets, routing

| Concern | Design |
|---|---|
| Config | `config :mica, …` (D7). One accessor wraps all reads. SaaS config lives in the SaaS. Mica ships a documented runtime example plus helpers, so operators don't copy 280 lines of `runtime.*.exs`. |
| Migrations | Ecto runs several migration paths. `Core.Release.migrate/0` runs Mica's path plus each extension's path, in timestamp order. Table ownership and baselines follow D8. |
| Repo | One `Core.Repo` per deployment, configured by the SaaS. SaaS schemas use it too. |
| Translations | Mica keeps `CoreWeb.Gettext` with its own `priv/gettext`. The SaaS has its own backend for its own domains. Mica's `eyra-*` domains are renamed to neutral names, and brand words become `Core.Brand` interpolations. Whether SaaS repos can override Mica copy is an open question. |
| Assets | Mica's JS hooks are resolvable from `deps/mica/assets`. The SaaS `app.js` merges them with its own hooks. Tailwind `content` includes `deps/mica`. Prism stays an npm dependency of both. Mica ships neutral icons; the SaaS serves its own logos, favicons and manifest. |
| Routing | `Next.Router` does `use CoreWeb.Router` and calls the Mica route macro. Overriding routes by shadowing them is the exception; prefer extension points (start pages, the sign-in page). |
| Menus, start pages | Extensions contribute menu items. The SaaS's builder decides layout and order. |
| Auth providers | Email, password and OTP sign-in are Mica core. Google and Apple are M-opt behind a provider behaviour. SURFconext and Centerdata are integrations that contribute their own routes. |
| Seeds, supervision | Seeds and supervisor children are declared per extension (`Core.children/1` plus `Extension.children/1`). |

### 3.6 Branding and theming

- **`Core.Brand` behaviour,** set with `config :mica, brand: Next.Brand`. It provides:
  - name, logos and favicon
  - support email
  - policy URLs
  - footer
  - email signature and mail-from
  - monitoring app name
  - invoice prefix
  - merchant and donation recipient
- **Default brand.** Mica ships a neutral one. Whether it says "Powered by Mica / Nova" is an open question.
- **Theming is Prism.** The SaaS supplies a Tailwind preset that extends `@novasoftwarefoundation/prism/tailwind.preset`. Pixel components use only Prism tokens.
- **Partner and pool logos** are supplied by the brand or by extensions, not stored in Mica.

### 3.7 Integrations

- **Behaviour in Mica, implementations elsewhere.** Each external integration is a behaviour in Mica plus implementation modules. Existing behaviours include:
  - `Systems.Payment.Provider`
  - `Systems.Storage.Backend`
  - the image catalog
  - `Frameworks.UserCheck`
  - auth providers
- **What Mica core contains:** the behaviours, local/dummy implementations for development and tests, and possibly generic cloud backends (open question).
- **Where the rest goes.** Under D2 and D3, Eyra-specific integrations (OPP, Yoda, SURFconext, Centerdata) live in the SaaS until their owner is decided.
- **Banking** is retired (D6). If bank reconciliation is ever needed, it becomes a new in-process integration, not a proxy.

### 3.8 Mica–Feldspar protocol (public contract)

- **Version 1 describes today's protocol exactly.**
  - The host side is in [`core/assets/js/feldspar_app.js`](../../core/assets/js/feldspar_app.js) and [`core/systems/feldspar`](../../core/systems/feldspar).
  - The app side is `LiveBridge` in `eyra/feldspar`.
- **Packaging and serving.** A Feldspar app is a zip with `index.html`. It is served from the local filesystem or a public S3 prefix, which makes it cross-origin.
- **Handshake:**
  - iframe → host: `{action: "app-loaded"}`
  - host → iframe: `{action: "live-init", locale}`, plus a transferred `MessagePort`
  - iframe → host: `{action: "resize", height}`
- **Commands over the port:**
  - app → host:
    - `CommandSystemLog {json_string}`
    - `CommandSystemDonate {key, json_string}`
    - `CommandSystemExit {code, info}`
    - `CommandSystemEvent {name}`
  - host → app:
    - `DonateSuccess {key, status}`
    - `DonateError {key, status, error}`
- **HTTP endpoints:**
  - `POST /api/feldspar/donate` with multipart fields `key`, `context`, `data`
  - `POST /api/feldspar/log`
  - both require authentication and are rate-limited (`:feldspar_data_donation`, `:feldspar_log`)
- **Recovery.** A localStorage key `feldspar:attempt:<scope>:<uuid>` marks an unfinished attempt.
- **Planned changes:**
  - A `protocol_version` in `live-init`, echoed by the app. A missing version means v1.
  - Explicit origin and source checks on both sides. Today the host posts with target `"*"`, and the app accepts the first `live-init` from any sender.
  - The upload context becomes an opaque, host-signed token with a documented public subset, so the protocol is not tied to Assignment.
  - Shared contract tests.
- **Where it's planned.** Track F in [plan.md](./plan.md#track-f--feldspar-summary) and `eyra/feldspar` `doc/nova-migration/plan.md`.

### 3.9 Extendability and scalability

**Extendability.** All of the following can be added from a SaaS repository without touching Mica:
- systems, tools and project items
- pool directors
- auth, payment and storage providers
- notifiers
- admin panels and menu items
- JS hooks
- migrations, seeds and translations

The lightweight path for third parties is Feldspar apps, which need no Elixir. Mica's stability promise covers the public behaviours and the protocol; internal modules are not public API.

**Scalability.** Composition happens at compile time, so there is no runtime registry cost. What remains:
- **Storage delivery.** It uses a node-local Oban queue (`storage_delivery_local_<node>`), because donations land on local disk first. Multi-node operators need shared temporary storage through the `:temp_file_store` behaviour; make that the default.
- **Feldspar app serving.** Serving from the local filesystem works on a single node only. Production uses S3 or a CDN.
- **Rate limits.** Decide which quotas must be cluster-wide.
- **Clustering.** The libcluster topology becomes operator config.
- **Feature flags.** Fix the default-on semantics.
- **Deployment model.** One SaaS per deployment; multi-tenancy is out of scope (D13).

---

## 4. Open questions

Decided questions are in [Decisions](#decisions). Still open:

1. **Integrations** (OPP, Yoda, SURFconext, Centerdata). Mica building blocks under Nova governance, separate Nova-owned packages, or Next? Until decided, they live in Next.
2. **Generic cloud backends** (S3/Tigris, Azure storage, Mailgun/SES). Mica core or integration packages?
3. **Mica's own branding.** Does a Mica-based SaaS show "Powered by Mica / Nova" by default (configurable), or nothing?
4. **Translations.** Do SaaS repositories need to override Mica's UI copy? If so, by which mechanism?
5. **Eyra-owned forks** used as Mica dependencies (`bamboo_phoenix`, `bamboo_ses`, `live_nest`, `packmatic`). Move them to Nova, upstream them, or keep them Eyra-maintained?
6. **Self.** Is it still deployed from `eyra/mono`? Will it follow Mica's reference SaaS or `novasoftwarefoundation/mica-saas`, and when?
7. **`eyra/mono` after the split.** Read-only/archived, or security fixes for Self deployments?
8. **Licence and copyright** (AGPL-3.0). Copyright holder after the move, and consequences for operators. Needs legal input.

The questions about release mechanics (binary name, `eyra/next` history) are listed in [plan.md](./plan.md#open-questions).

<sub>Written by an AI agent (Claude Code · Claude Opus 5.5, herdr-projects nova-migration · t-0001).</sub>
