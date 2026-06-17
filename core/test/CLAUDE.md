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

#### LiveContext for Dependencies

Embedded views that declare `dependencies()` get those values injected from parent via `LiveContext`. When testing with `live_isolated`, you must pass a LiveContext in the session for dependencies to be available in socket.assigns:

```elixir
alias Frameworks.Concept.LiveContext

setup ctx do
  user = Factories.insert!(:member)
  {:ok, ctx} = login(user, ctx)
  conn = ctx[:conn] |> Map.put(:request_path, "/admin/system")

  # Create LiveContext with all dependencies the view needs
  context = LiveContext.new(%{
    current_user: user,
    locale: :en,
    # Include other dependencies declared in dependencies()
    bank_accounts: [],
    citizen_pools: []
  })

  {:ok, conn: conn, user: user, context: context}
end

test "event handler works", %{conn: conn, context: context} do
  # Pass context in session - key must be "live_context"
  {:ok, view, _html} = live_isolated(conn, Admin.SystemView,
    session: %{"live_context" => context}
  )

  # Now event handlers that pattern match on assigns will work
  _ = view |> render_click("create_citizen_pool")

  assert view |> has_element?("[data-testid='system-view']")
end
```

**Why this matters:**
- The view's `dependencies()` function declares what it needs (e.g., `[:current_user, :locale, ...]`)
- The `CoreWeb.Live.Hook.Context` hook extracts these from LiveContext and assigns to socket
- Event handlers often pattern match on `%{assigns: %{locale: locale}}` - this fails without LiveContext
- Without LiveContext, the view model may render but event handlers will fail with "no function clause matching"

#### Basic Embedded View Testing

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

## When to write which kind of test

Eyra has four test categories. They live in different directories, have different mechanics, and answer different questions. Pick the right one *before* writing.

| Category | Directory | What it answers | Speed | External systems |
|---|---|---|---|---|
| **Unit** | `test/systems/...`, `test/core_web/...` | "Does this function / changeset / state-machine clause behave correctly, including edge cases and error branches?" | ms | mocked via Mox |
| **Feature (Wallaby)** | `test/features/` | "Does this user journey work end-to-end through the UI, happy path?" | seconds | mocked via Mox |
| **E2E (Playwright)** | `test/e2e/` | "Does the deployed system work in a real browser, with real external integrations (real OPP sandbox, real Feldspar, real storage)?" | tens of seconds | real |
| **Smoke (Playwright)** | `test/smoke/` | "Did the latest deploy survive its own boot? Are the critical endpoints reachable?" | seconds | real |

### Unit (`test/systems/...`)

Use for:
- State-machine clause coverage (each `when` guard, each branch)
- Changesets, validations
- Error / failure branches (`{:error, _}` paths)
- Business-logic edges: "rapid double-click doesn't create duplicates," "button is disabled when reward = 0," "second transaction on same assignment uses fresh provider uid"
- `live_isolated` tests for view-builder + event-handler logic without full browser stack

If the question is "what does function X return when input is Y?" — unit.
If the question is "what does the LV render when assigns look like Z?" — `live_isolated` LV test.

### Feature (`test/features/`)

Use for:
- One *user journey* walked end-to-end through the UI, happy path only
- Cross-system flows where the UI integration matters
- Multi-session interactions (researcher + participant)

**Edge cases do NOT belong here.** Disabled-button state, double-click idempotency, error branches, state-machine transitions, "field X is hidden when Y" — these all live in unit tests or `live_isolated` LV tests. Feature tests are slow (browser, chromedriver, full LV stack); don't load them with assertions a unit test can make in 1ms.

If the question is "does the user journey from signin → action → result work?" — feature.

Mechanics, scope, multi-session, testids, waiting: `test/features/CLAUDE.md`.

### E2E (`test/e2e/`)

Use for:
- Verifying the *deployed system* works against real external dependencies (OPP sandbox, Feldspar storage backends, real Phoenix runtime)
- Things only real deployments break: cookies across navigation, CSP headers, asset pipeline, environment-specific config

If the journey can be mocked via Mox without losing what you're testing → feature, not E2E. E2E is for the "real integrations" bucket; if it doesn't exercise a real external system, it's a feature test in disguise.

Mechanics: `test/e2e/CLAUDE.md`.

### Smoke (`test/smoke/`)

Use for:
- Post-deploy verification — does the env at URL X respond to GET /, do the auth endpoints return their expected shape, does Feldspar load
- Run as part of the deploy pipeline against a freshly-rolled env

Smoke tests are *not* feature tests with a shorter list. They're targeted assertions on specific endpoints/pages that tell you a deploy is alive.

### How the four interact

- A new flow gets a **happy-path feature test** (one journey, one `feature` block) plus **unit tests for every state-machine clause and error branch.** That's the default.
- An **E2E test** is added on top *only* when a real external integration needs verification (OPP sandbox, real storage upload). Otherwise the feature test covers it.
- **Smoke** is for deploy-time, not for verifying behavior.

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