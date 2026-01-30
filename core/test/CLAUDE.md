# Test-Specific Guidelines for Claude Code

This file contains testing patterns and learnings specific to the test suite.

## Signal Testing Patterns

### Signal Isolation Challenges

#### LiveView Process Isolation
When testing LiveViews with signals, be aware that:
- **LiveView runs in a separate process** from your test
- `isolate_signals()` in the test setup only affects the test process
- LiveView event handlers (like `handle_event("abort", ...)`) run in the LiveView process

```elixir
# This WON'T work as expected:
setup do
  isolate_signals()  # Only affects test process
  # ...
end

test "clicking abort", %{conn: conn} do
  {:ok, view, _html} = live_isolated(conn, MyLiveView)

  # This runs in LiveView process - no signal isolation!
  view |> element("[phx-click='abort']") |> render_click()
end
```

#### Solution Patterns

1. **Test functions directly** instead of through LiveView clicks:
```elixir
test "abort clears file", %{conn: conn, tool: tool} do
  # Setup initial state
  import_session = Factories.insert!(:paper_ris_import_session, %{
    status: :activated,
    phase: :prompting
  })

  # Mount view to verify initial state
  {:ok, _view, html} = live_isolated(conn, ImportView,
    session: %{"tool" => tool})
  assert html =~ "test.ris"

  # Call function directly in test process (signal isolation works!)
  Zircon.Public.abort_import!(import_session)

  # Verify results
  updated_file = Repo.get!(Paper.ReferenceFileModel, file_id)
  assert updated_file.status == :archived
end
```

2. **Create expected data** to avoid workflow errors:
```elixir
# If signals expect workflow items to exist, create them
setup do
  isolate_signals()

  # Create workflow item that signal handlers expect
  workflow = Factories.insert!(:workflow)
  tool_ref = Factories.insert!(:workflow_tool_ref,
    zircon_screening_tool: tool)
  Factories.insert!(:workflow_item,
    workflow: workflow,
    tool_ref: tool_ref)

  %{tool: tool}
end
```

3. **Use `isolate_signals(except: [...])`** carefully:
```elixir
# This attempts to allow certain switches through
# BUT remember it still only works in test process!
isolate_signals(except: [Systems.Paper.Switch])
```

### Testing Multi-Based Functions

When testing functions that use `Ecto.Multi`:

```elixir
test "multi operations are atomic" do
  # Setup
  session = Factories.insert!(:import_session)
  ref_file = Factories.insert!(:reference_file)

  # Test atomicity by making one operation fail
  # Both should rollback
  assert_raise Ecto.InvalidChangesetError, fn ->
    Multi.new()
    |> Paper.Public.multi_abort_import_session(session)
    |> Multi.update(:fail, invalid_changeset())  # Force failure
    |> Repo.transaction()
  end

  # Verify nothing changed
  assert Repo.get!(ImportSession, session.id).status == :activated
end
```

### Signal Assertion Patterns

```elixir
# Only works if signals reach test process
test "signal is dispatched" do
  isolate_signals()

  # This runs in test process, so signal is captured
  Paper.Public.archive_reference_file!(file_id)

  assert_signal_dispatched({:paper_reference_file, :updated})
end

# For LiveView tests, can't easily assert signals
test "LiveView dispatches signal" do
  {:ok, view, _} = live_isolated(conn, MyLiveView)

  # This won't work - signal dispatched in LiveView process
  view |> element("button") |> render_click()

  # Can't assert signal here - it was sent in different process
  # Instead, verify the side effects (database changes, etc.)
  assert Repo.get!(Model, id).status == :expected
end
```

## Factory Patterns

### Use Associations Over Foreign Keys
```elixir
# ✅ GOOD: Use associations
Factories.insert!(:paper_ris_import_session, %{
  reference_file: reference_file,
  paper_set: paper_set
})

# ❌ AVOID: Setting foreign keys directly
Factories.insert!(:paper_ris_import_session, %{
  reference_file_id: reference_file.id,
  paper_set_id: paper_set.id
})
```

### Preload Before Asserting
```elixir
# Always preload associations before assertions
updated_tool = tool |> Repo.preload(:annotations)
assert length(updated_tool.annotations) == 3
```

## LiveView Testing Patterns

### Setting Request Path
```elixir
# Required for some LiveViews that check the path
conn = conn |> Map.put(:request_path, "/zircon/screening/import")
{:ok, view, html} = live_isolated(conn, ImportView, session: %{})
```

### Testing Event Handlers

**Always send events directly instead of clicking elements:**

```elixir
# ✅ CORRECT: Send event directly to LiveView
test "button triggers event", %{conn: conn} do
  {:ok, view, _html} = live_isolated(conn, MyView, session: %{})

  # Verify button exists
  assert view |> has_element?("[data-testid='my-button']")

  # Send event directly - avoids CSS selector issues
  view |> render_click("my_event")

  # Verify result
  assert view |> has_element?("[data-testid='expected-result']")
end

# ❌ WRONG: Don't click on elements
view |> element("[data-testid='my-button']") |> render_click()
# This can cause "invalid css selector" errors in LiveView tests
```

**Why send events directly:**
- Avoids CSS selector errors in LiveView test infrastructure
- Cleaner and more direct - tests the event handler, not DOM manipulation
- More reliable for isolated LiveView tests
- Works consistently across different button/action types

### Testing Embedded LiveViews
```elixir
# Parent view
{:ok, parent_view, parent_html} =
  live_isolated(conn, ParentView, session: %{})

# Can also test embedded view directly
{:ok, embedded_view, embedded_html} =
  live_isolated(conn, EmbeddedView,
    session: %{"session_id" => session.id})

# But remember: they run in separate processes!
```

## Common Test Helpers

### Signal Test Helper
```elixir
import Frameworks.Signal.TestHelper

setup do
  # Isolate all signals except TestHelper
  isolate_signals()

  # Or allow specific switches
  isolate_signals(except: [Systems.Paper.Switch])

  # Always clean up
  on_exit(fn ->
    restore_signal_handlers()
  end)
end
```

### Database Sandbox
All tests use `Ecto.Adapters.SQL.Sandbox` for isolated database transactions that rollback after each test.

## Debugging Test Failures

### Process PID Tracking
```elixir
test "debug process isolation" do
  IO.puts("Test process: #{inspect(self())}")

  {:ok, view, _} = live_isolated(conn, MyLiveView)
  # LiveView mount will show different PID

  # Add debugging to your LiveView:
  # def mount(_params, _session, socket) do
  #   IO.puts("LiveView process: #{inspect(self())}")
  #   {:ok, socket}
  # end
end
```

### Signal Flow Debugging
```elixir
# Temporarily add logging to Signal.Private.dispatch
defp signal_handlers do
  handlers = case Process.get(:signal_handlers_override) do
    nil ->
      IO.puts("PID #{inspect(self())}: Using default handlers")
      Keyword.get(config(), :handlers, [])
    override ->
      IO.puts("PID #{inspect(self())}: Using override: #{inspect(override)}")
      override
  end
  # ...
end
```

## Test Organization

### Integration Tests
For complex signal flows, create focused integration tests:
```elixir
# test/systems/zircon/screening/abort_prompting_integration_test.exs
defmodule Systems.Zircon.Screening.AbortPromptingIntegrationTest do
  use CoreWeb.ConnCase, async: false  # async: false for signal tests

  describe "abort from prompting phase" do
    test "complete flow", %{conn: conn} do
      # Setup complete scenario
      # Test the full flow
      # Verify all side effects
    end
  end
end
```

### Async Considerations
- Tests with signals often need `async: false`
- Database isolation still works with `async: false`
- Use `async: true` when not testing signals for better performance

## Wallaby Feature Testing

### Multi-Session Tests
Use `@sessions N` to create multiple browser sessions:
```elixir
@sessions 2
@tag :feature
feature "two users interact", %{sessions: [researcher, participant]} do
  # researcher and participant are separate browser sessions
end
```

### data-testid Naming Convention
Use this convention to avoid CSS selector collisions:

- **Main elements**: `{element}_{id}` → `card_7`
- **Actions/buttons**: `{event}__action__{element}_{id}` → `delete__action__card_7`

**Separators**:
- `_` for words within a segment (e.g., `create_first_item`)
- `__` for hierarchy levels (e.g., `delete__action__card_7`)

**Why**: CSS prefix selectors like `[data-testid^='card_']` only match main cards, not action buttons.

```elixir
# In clickable_card.ex
data-testid={"card_#{@id}"}                           # Main card
data-testid={"show_more__action__card_#{@card_id}"}   # Show more button
data-testid={"delete__action__card_#{@card_id}"}      # Delete action
```

### Waiting for LiveView to be Ready (Stale Reference Prevention)
After navigation, LiveView may still be connecting or morphing the DOM. Wait for the `.phx-connected` class:

```elixir
# ❌ WRONG: Element becomes stale during LiveView DOM morphing
researcher |> click(Query.css(@card_selector))
researcher |> assert_has(Query.css("[data-testid='my-button']"))
researcher |> click(Query.css("[data-testid='my-button']"))  # StaleReferenceError!

# ✅ CORRECT: Wait for LiveView WebSocket connection to be established
researcher |> click(Query.css(@card_selector))
researcher |> assert_has(Query.css("[data-phx-main].phx-connected"))  # Wait for LiveView ready
researcher |> assert_has(Query.css("[data-testid='my-button']"))
researcher |> click(Query.css("[data-testid='my-button']"))
```

**Why this works**: Phoenix LiveView adds `.phx-connected` class to the main container (`[data-phx-main]`)
when the WebSocket connection is established and the view is ready. Before this, the DOM may be morphing
and elements can become stale between `find` and interaction.

### Debugging Wallaby Tests
When a selector doesn't match, **add logging** to see what's actually on the page:

```elixir
# Log all data-testids on the page
html = Wallaby.Browser.page_source(session)
testids = Regex.scan(~r/data-testid="([^"]+)"/, html) |> Enum.map(&List.last/1)
IO.puts("\n=== ALL DATA-TESTIDS ===")
testids |> Enum.each(&IO.puts/1)
IO.puts("=== END ===\n")
```

**Key principle**: Don't assume bugs in Wallaby. Always log and verify what's actually rendered.

### Getting Element Attributes
```elixir
# Find element and get attribute
element = session |> find(Query.css("[data-testid^='card_']"))
testid = Wallaby.Element.attr(element, "data-testid")
# Extract ID: "card_7" -> "7"
card_id = testid |> String.replace("card_", "")
```

### CSS Attribute Selectors
- `^=` starts with: `[data-testid^='card_']` matches `card_7`
- `$=` ends with: `[data-testid$='_button']` matches `submit_button`
- `*=` contains: `[data-testid*='action']` matches `delete__action__card_7`
- `=` exact match: `[data-testid='card_7']` matches only `card_7`

### Feature Test File Template
```elixir
defmodule CoreWeb.Features.MyFeatureTest do
  use CoreWeb.FeatureCase

  @card_selector "[data-testid^='card_']"

  @sessions 2
  @tag :feature
  feature "description", %{sessions: [user1, user2]} do
    # Setup users
    password = Factories.valid_user_password()
    user = Factories.insert!(:member, %{
      password: password,
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      creator: true
    })

    # Login
    user1
    |> visit("/user/signin")
    |> click(Query.css("[data-testid='signin-tab-creator']"))
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: user.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))

    # Test actions...
  end
end
```

## Pre-commit Hook Rules

### Never Use --no-verify to Skip Failing Tests

**Critical**: Never use `git commit --no-verify` to bypass pre-commit hooks when tests fail.

If a test fails during pre-commit:
1. **Investigate the failure** - even if it seems unrelated to your changes
2. **Fix the test** - if it's flaky, fix the flakiness
3. **Only then commit** your changes

**Why this matters**:
- A failing test indicates something is broken
- "Unrelated" test failures may actually be caused by your changes
- Pushing broken code to CI wastes time and resources
- CI will fail anyway if the test is actually broken

**Flaky tests must be fixed**: If a test passes on retry but failed before, it's flaky. Flaky tests must be fixed - not ignored. Run with the same seed to reproduce: `mix test path/to/test.exs --seed <seed>`

**The only acceptable use of --no-verify**: When the pre-commit hook itself is broken (not the tests).