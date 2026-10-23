# Storybook for Pixel and Next components — spec

Status: implemented on `feature/storybook`; spike results below.

## Goal

A storybook.js-style catalog of our Phoenix components: sidebar, variations, docs taken from
`attr`/`slot`, and a live playground. It runs locally and on the testing environment.

## Decision: adopt `phoenix_storybook`, don't build

[`phoenix_storybook`](https://hex.pm/packages/phoenix_storybook) v1.5.0 (2026-09-15, about 35k
downloads, no security advisories) already provides:

- function component and live_component stories, page stories, example stories
- a sidebar built from the folder tree of `*.story.exs` files
- a playground that edits attributes and slots live (like Storybook "Controls")
- docs from `@doc`/`@moduledoc` and attribute tables from `attr`/`slot`
- variation groups, wrapper templates, `psb-assign` events for modals, iframe sandboxing,
  themes and color mode, links to the source files

Writing our own would mean rebuilding all of this. Any gap goes upstream as a PR.

## Fit with this repo

| Item | Current | Needed | Impact |
|---|---|---|---|
| `phoenix` | 1.8.1 | `~> 1.8.1` | ok |
| `phoenix_live_view` | 1.1.13 | `~> 1.1.21 or ~> 1.2.0` | **bump LV first** (patch releases within 1.1) |
| Tailwind | 3.3.6 (`assets/tailwind.config.js`) | docs assume v4 | storybook's own CSS is precompiled, uses the `psb:` prefix and sits in CSS layers; our Tailwind 3 output has no layer and would override it, preflight included → spike S1 |
| `mdex` (transitive) | – | Rust NIF, precompiled | check the Docker builder image (spike S3) |
| Pixel components | ~173 function components, 739 `attr`, 12 live_components | – | the attr metadata is rich enough to generate stories from |

## Scope

In: Pixel (`mica/frameworks/pixel/components/*`) and Next-owned components, function
components and live_components. The editor is the built-in playground; nothing extra to build.

Out: visual regression testing, an in-browser HEEx code editor.

## Design

### Ownership (Nova boundary)

There are two storybooks, one per owner, so the boundary holds. The Mica one must not name
Next/Self modules or Eyra specifics; `boundary_check.exs` covers both folders.

| Piece | Mica (Pixel) | Next |
|---|---|---|
| Backend module | `CoreWeb.Storybook` in `mica/lib/core_web/storybook.ex` | `Next.Storybook` in `next/lib/storybook.ex` |
| Route | `/admin/storybook` in `CoreWeb.Router` | `/admin/storybook-next` from the Next routes, `session_name: :next_storybook`, `pipeline: false` |
| Stories | `mica/storybook/**/*.story.exs` | `next/storybook/**/*.story.exs` |

Shared: the story generator `mix storybook.gen SOURCE CONTENT [--prefix MODULE] [--check]`
(`mica/lib/mix/tasks/storybook.gen.ex`), run for both storybooks by the aliases
`mix storybook.stories` and `mix storybook.check`, and the JS entry `assets/js/storybook.js`.

### Stories: generated + curated ("Both")

`phoenix_storybook` only finds stories through files. To get both automatic and curated
stories:

- `mix storybook.gen` reads `Module.__components__/0` (attr/slot metadata from
  `Phoenix.Component`) for every module under the source folder and writes a `*.story.exs` for
  each public component **that doesn't have a story yet**. The generated file has one `:default`
  variation:
  - attrs with a `default` are left to the component
  - required attrs take their first `examples:`/`values:` entry, else a placeholder by type
    (`:string` → `"Lorem ipsum"`, `:boolean` → `false`, `:integer` → `1`, `:list` → `[]`,
    `:map` → `%{}`, other types → `nil`)
  - the default slot gets text, required named slots get `<:name>Lorem ipsum</:name>`
- One flat folder per module, minus `--prefix` (`button/`, `button.face/`), so a function never
  shares its storybook path with a nested module of the same name.
- Curating means editing the generated file. The generator never overwrites a file.
- `mix storybook.check` fails when a public component has no story; it runs in CI.
- `mica/test/core_web/storybook_test.exs` and `next/test/storybook_test.exs` render every story,
  so a component change that breaks its story fails the suite.

LiveViews and live components are skipped by the generator: their components render with the
state of the process. Their stories are written by hand when needed.

### Assets

- `assets/js/storybook.js` sets `window.storybook = { Hooks }`; the hooks moved from `app.js`
  into `assets/js/hooks.js`, shared by both entries. Second esbuild entry point.
- `css_path` is the app's own `/assets/app.css`: the storybook imports it into the `app` CSS
  layer, so it can't override the storybook's own (prefixed, `utilities`-layer) styles (S1). The
  Tailwind content globs include `*.story.exs`.
- `sandbox_class: "font-body"`, the base font of `<body>` in the app.
- `live_reload` gets `~r"(mica|next)/storybook/.*(exs)$"`.

### Routing and access

```elixir
scope "/" do
  storybook_assets()
end

scope "/" do
  pipe_through [:browser, :storybook_guard]
  live_storybook "/admin/storybook", backend_module: CoreWeb.Storybook
end
```

`:storybook_guard` is one plug:
- the `:storybook` feature is off → 404. Feature flags are read at runtime through
  `Core.FeatureFlags`, the same way `:e2e` works; prod never enables it
  (`RuntimeConfig.features/2` gets the same reject rule as `:e2e`).
- the user is not an admin (`Admin.Public.admin?/1`) → redirect to `/access_denied`.
- in dev the flag is on in `config/dev.exs`; the admin check stays.

The LiveView websocket mount needs a session token signed during the guarded HTTP render, and
the storybook holds no data. So the plug alone is enough; no `on_mount` hook (we can't add one
to the library's LiveViews anyway).

Releases: keep the `Docs` chunks (`strip_beams: [keep: ["Docs"]]`), otherwise the docs tabs
are empty. Set `compilation_mode: :eager` outside dev (that is the library default).

### Cleanup / cutover

- Delete `CoreWeb.ComponentTestLive` and its dev routes `/component_test(/:component)`;
  update `next/test/snapshots/self/routes.exs`.
- `Systems.Admin.TypographyPage` becomes a `:page` story in the Mica storybook. Remove the
  page, its route, its `grant_access` line in `Core.Authorization` and any admin menu entry.

## Phases

1. **LV bump**: `phoenix_live_view` 1.1.13 → latest 1.1.x. Separate PR, full suite.
2. **Spikes** S1–S3 (below), each ending in a yes/no answer.
3. **Install**: dep, backend module, routes + guard, feature flag, assets, formatter, release
   docs chunks. One hand-written story (`Button.dynamic`) as the smoke test.
4. **Generator**: `mix storybook.gen` (+ `--check` in CI); generate stories for all Pixel and
   Next components and commit them. Add the Next backend and route.
5. **Curate**: hand-tune Button, Text, Card, Panel, Form inputs, ModalView, Tabbed and Table;
   write templates for the modals, panels and live_components.
6. **Cutover**: remove `ComponentTestLive`, update the routes snapshot, move typography into a
   page story.

## Spike results

- **S1 CSS**: yes. With `app.css` as `css_path`, Pixel renders as in the app (fonts, colors) and
  the storybook UI is unaffected; checked in the browser.
- **S2 release**: outside dev the backend compiles every story at build time (`:eager`) and the
  story modules are written as `.beam` files (219 in `_build/test`), so the release needs no
  story files at runtime.
- **S3 Docker**: `mdex_native` ships precompiled NIFs for `x86_64`/`aarch64-unknown-linux-gnu`;
  the builder (`elixir:1.19.6-otp-27`, Debian) and runtime (`debian:bookworm-slim`) are glibc.
  Not built in Docker yet.

## Acceptance

- `/admin/storybook` (Pixel) and `/admin/storybook-next` (Next) in dev list every public component; each
  one renders its `:default` variation and shows its attribute docs and playground.
- On testing (flag on) an admin can open both; a non-admin gets `/access_denied`; with the flag
  off the routes return 404. On prod the flag can't be turned on.
- `mix storybook.gen` is idempotent (a second run writes nothing); `--check` fails in CI when a
  component has no story.
- The 8 curated components have hand-written variations beyond `:default`.
- `/component_test` and the admin typography page are gone; typography is a story page.
- `mix compile --warnings-as-errors`, `mix test --warnings-as-errors` and `boundary_check.exs`
  pass.

## Decisions

| # | Question | Decision |
|---|---|---|
| D1 | Build or adopt | Adopt `phoenix_storybook`; gaps go upstream |
| D2 | Editor | The built-in playground is enough |
| D3 | Stories | Generated + curated |
| D4 | Where it runs | Dev + testing, admin only, behind the `:storybook` flag |
| D5 | Next components | Included, through a second storybook |
| D6 | CI gate | `mix storybook.gen --check` enforced |
| D7 | Cutover | Delete `ComponentTestLive`; move `TypographyPage` into a page story |
| D8 | First curated set | Button, Text, Card, Panel, Form inputs, ModalView, Tabbed, Table |
