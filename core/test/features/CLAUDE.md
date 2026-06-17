# Wallaby Feature Tests

Browser-based tests using Wallaby (Elixir WebDriver) that walk a user
journey end-to-end through the UI.

For *which kind of test to write* (unit / feature / e2e / smoke), see
`core/test/CLAUDE.md` → "When to write which kind of test".

## When to add a broad journey test on top of narrow ones

Don't, by default. Cost is duplication.

Add a broad journey test on top of narrow ones **only when narrow tests Factory-skip a signal chain that has realistic breakage risk.** All three conditions must hold:

1. The flow has **signal chains or state machines crossing system boundaries** (e.g. Eyra payment flow: task-completion → reward state → wallet entry).
2. Those chains have **broken before** or are **realistic to break** (look at the bug-fix history — if the answer is "yes, the signal handler stops firing every few months," that's the case).
3. The narrow tests **Factory-build the intermediate state**, bypassing the chain (so they can't catch chain breakage).

When any one is false, narrow is enough. Don't preemptively add coverage for breakage that hasn't happened.

## Running feature tests

```bash
mix test.feature                                       # all feature tests
mix test.feature test/features/smoke_test.exs          # one file
WALLABY_HEADLESS=false mix test.feature ...            # with a visible browser
```

`mix test.feature` runs `test --only feature`.
`mix test.unit` runs `test --exclude feature`.
`mix test.ci` runs both halves + JS.

## Key principles

### 1. Never rely on labels

Labels change with translations. Always use `data-testid`.

```elixir
# WRONG — label can change
session |> click(Query.text("Start browsing"))

# CORRECT — stable selector
session |> click(Query.css("[data-testid='onboarding-continue']"))
```

### 2. Wait on the destination, not on `.phx-connected`

After an action that navigates (click, visit, form submit), the next
assertion must be on something visible on the **target page** — never on
framework state of the page you just left.

- **Wait on a user-visible signal**, not `.phx-connected` and not `data-phx-main`. The destination's own `data-testid` *is* the signal.
- **Let `assert_has` do the polling.** Wallaby's `assert_has` retries up to `max_wait_time` (5s default). One `assert_has` on a target-page testid handles both "wait for navigation" and "verify page rendered" in one step.
- **No `assert_has(".phx-connected")` after navigation.** It waits on the source page's WebSocket handshake instead of the destination's content; it doesn't prove the next page is ready; and it can leave chromedriver tearing down an active WebSocket on the next `visit` — surfacing as a Wallaby HTTPoison timeout.
- **Helpers like `sign_in` end at a *negative* signal on the source page** (`refute_has(signin-form)` — proves we left). They MUST NOT add positive waits on the destination — that belongs to the caller, on the page they actually need.

```elixir
# ✅ CORRECT — wait on a user-visible element of the destination
session
|> sign_in(user, password)
|> visit("/user/onboarding")
|> assert_has(Query.css("[data-testid='profile-view']"))

# ✅ CORRECT — same rule for in-page clicks. The destination testid wait
# also prevents stale-element races, because the assertion polls until the
# DOM morph settles.
researcher
|> click(Query.css(@card_selector))
|> assert_has(Query.css("[data-testid='my-button']"))
|> click(Query.css("[data-testid='my-button']"))

# ❌ WRONG — waits on source/framework state, not destination content
session
|> sign_in(user, password)
|> assert_has(Query.css("[data-phx-main].phx-connected"))
|> visit("/user/onboarding")
```

The same rule applies to E2E (Playwright) tests in `core/test/e2e/` — prefer `expect(...).toBeVisible()` on a target-page `data-testid`.

### 3. Multi-Session Tests

Use `@sessions N` to create multiple browser sessions:

```elixir
@sessions 2
@tag :feature
feature "two users interact", %{sessions: [researcher, participant]} do
  # researcher and participant are separate browser sessions
end
```

### 4. `data-testid` naming convention

- **Main elements**: `{element}_{id}` → `card_7`
- **Actions/buttons**: `{event}__action__{element}_{id}` → `delete__action__card_7`

Separators:
- `_` within a segment (e.g. `create_first_item`)
- `__` between hierarchy levels (e.g. `delete__action__card_7`)

CSS prefix selectors like `[data-testid^='card_']` then only match main cards, not action buttons.

```elixir
data-testid={"card_#{@id}"}                          # main card
data-testid={"show_more__action__card_#{@card_id}"}  # show-more action
data-testid={"delete__action__card_#{@card_id}"}     # delete action
```

CSS attribute selector reference:

- `^=` starts with: `[data-testid^='card_']` matches `card_7`
- `$=` ends with: `[data-testid$='_button']` matches `submit_button`
- `*=` contains: `[data-testid*='action']` matches `delete__action__card_7`
- `=` exact: `[data-testid='card_7']` matches only `card_7`

### 5. Sign in via the helper, not inline steps

`CoreWeb.FeatureCase` exposes `sign_in_as_participant/3` and `sign_in_as_creator/3`. The signin page renders both tab panels in the DOM, with tab-scoped testids. The helpers pick the right ones. **Don't** inline the visit + fill + click steps.

### 6. Unique testids when a component is rendered twice

If a component appears in multiple panels/contexts on the same page (the signin form is the canonical example — it lives in both tab panels), namespace the testid value at the source. Don't try to scope at the test site with parent selectors or `:visible` filters — both are brittle.

## Debugging

When a selector doesn't match, log what's actually on the page:

```elixir
html = Wallaby.Browser.page_source(session)
testids = Regex.scan(~r/data-testid="([^"]+)"/, html) |> Enum.map(&List.last/1)
IO.inspect(testids, label: "Available data-testids")
```

Don't assume bugs in Wallaby — log and verify what was actually rendered first.

Getting an element attribute (e.g. to extract an id from a `card_N` testid):

```elixir
element = session |> find(Query.css("[data-testid^='card_']"))
testid = Wallaby.Element.attr(element, "data-testid")
card_id = testid |> String.replace("card_", "")
```

## File template

```elixir
defmodule CoreWeb.Features.MyFeatureTest do
  use CoreWeb.FeatureCase

  @card_selector "[data-testid^='card_']"

  @tag :feature
  feature "description", %{session: session} do
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    sign_in_as_creator(session, user, password)

    # Test actions...
  end
end
```
