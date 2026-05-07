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

### 2. Wait for LiveView to be ready
After navigation, wait for `.phx-connected` to avoid stale element errors.

```elixir
session
|> click(Query.css("[data-testid='some-link']"))
|> assert_has(Query.css("[data-phx-main].phx-connected"))  # Wait for LiveView
|> assert_has(Query.css("[data-testid='expected-element']"))
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
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
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
