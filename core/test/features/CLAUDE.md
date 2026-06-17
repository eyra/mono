# Wallaby Feature Tests

These are browser-based feature tests using Wallaby (Elixir WebDriver).

See also: `core/test/CLAUDE.md` for detailed Wallaby patterns.

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
