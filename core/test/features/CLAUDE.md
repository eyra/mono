# Wallaby Feature Tests

These are browser-based feature tests using Wallaby (Elixir WebDriver).

See also: `core/test/CLAUDE.md` for detailed Wallaby patterns.

## Scope policy

**Feature tests walk a *user journey* end-to-end through the UI, happy path only.** One `feature` block per journey. External systems are mocked (`Systems.Payment.ProviderMock`, etc.). A journey can span multiple USCs — e.g. *"participant earns reward and cashes out"* is one journey across UC-OPP-05 + UC-OPP-06; it gets *one* feature test, not three.

**Edge cases do NOT belong in feature tests.** Disabled-button state, double-click idempotency, error branches, state-machine transitions, "field X is hidden when Y" — these all live in:

- **Unit tests** (`test/systems/...`) for state-machine / business-logic edges
- **`live_isolated` LV tests** (`test/systems/.../*_view_test.exs` or `*_handlers_test.exs`) for UI-state assertions

Feature tests are slow (browser, chromedriver, full LV stack). Use them for one thing: *does the user journey work end-to-end?* Don't load them with assertions a unit test can make in 1ms.

## When to add a broad journey test on top of narrow ones

Don't, by default. Cost is duplication.

Add a broad journey test on top of narrow ones **only when narrow tests Factory-skip a signal chain that has realistic breakage risk.** All three conditions must hold:

1. The flow has **signal chains or state machines crossing system boundaries** (e.g. Eyra payment flow: task-completion → reward state → wallet entry).
2. Those chains have **broken before** or are **realistic to break** (look at the bug-fix history — if the answer is "yes, the signal handler stops firing every few months," that's the case).
3. The narrow tests **Factory-build the intermediate state**, bypassing the chain (so they can't catch chain breakage).

When any one is false, narrow is enough. Don't preemptively add coverage for breakage that hasn't happened.

## Key Principles

### 1. Never rely on labels
Labels change with translations. Always use `data-testid` attributes.

```elixir
# WRONG - label can change
session |> click(Query.text("Start browsing"))

# CORRECT - stable selector
session |> click(Query.css("[data-testid='onboarding-continue']"))
```

### 2. Wait on the destination, not on `.phx-connected`
After navigation, wait on a user-visible `data-testid` of the **target page**.
`assert_has` already polls — that one assertion both waits for the navigation
and verifies the page rendered.

Do not insert `assert_has(".phx-connected")` between an action and the target
assertion: it waits on the *source* page's framework state, doesn't prove the
next page is ready, and can leave chromedriver tearing down an active
WebSocket on the next `visit` — surfacing as a Wallaby HTTPoison timeout.

See `core/test/CLAUDE.md` → "Waiting After Navigation — Project Policy" for
the full rule.

```elixir
session
|> click(Query.css("[data-testid='some-link']"))
|> assert_has(Query.css("[data-testid='expected-element']"))  # one wait, on the target
```

### 3. Use data-testid naming conventions
```
element_id          -> card_7, form_signup
action__element_id  -> delete__action__card_7
```

### 4. Debug with logging
When selectors don't match, log what's actually on the page:

```elixir
html = Wallaby.Browser.page_source(session)
testids = Regex.scan(~r/data-testid="([^"]+)"/, html) |> Enum.map(&List.last/1)
IO.inspect(testids, label: "Available data-testids")
```

## Running Feature Tests

```bash
# All feature tests
mix test test/features --include feature

# Single test
mix test test/features/smoke_test.exs --include feature

# With debug output
mix test test/features/smoke_test.exs --include feature --trace
```

## Test Structure

```elixir
defmodule CoreWeb.Features.MyFeatureTest do
  use CoreWeb.FeatureCase

  @tag :feature
  feature "description", %{session: session} do
    session
    |> visit("/path")
    |> assert_has(Query.css("[data-testid='target-page-element']"))
    |> click(Query.css("[data-testid='my-button']"))
    |> assert_has(Query.css("[data-testid='expected-result']"))
  end
end
```

## Multi-Session Tests

```elixir
@sessions 2
@tag :feature
feature "two users interact", %{sessions: [user1, user2]} do
  # user1 and user2 are separate browser sessions
end
```
