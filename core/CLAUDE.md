# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CRITICAL DEBUGGING PRINCIPLE

**NEVER ASSUME - ALWAYS INVESTIGATE**

Before attempting any fix:
1. **Trace the actual error** - Find where the error originates, not where you think it might be
2. **Verify data structures** - Check what data is actually being passed vs. what's expected
3. **Understand the context** - Know why there's a mismatch before proposing solutions
4. **Test your hypothesis** - Verify your understanding before making changes

Making changes based on assumptions without investigation leads to:
- Fixing the wrong problem
- Breaking other parts of the system
- Missing the real issue entirely

Always investigate first, understand second, fix third.

## Development Commands

### Setup and Dependencies
- `mix setup` - Full project setup (deps, database, assets)
- `mix deps.get` - Install Elixir dependencies
- `cd assets && npm install` - Install frontend dependencies

### Database
- `mix ecto.setup` - Create and migrate database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database
- `mix ecto.reset.link` - Reset with link bundle seeds

### Testing
- `mix test --warnings-as-errors` - Run all tests (ALWAYS use this)
- `mix test test/path/to/specific_test.exs --warnings-as-errors` - Run a specific test file
- `mix test --cover --warnings-as-errors` - Run tests with coverage

### Development Server
- `mix phx.server` or `mix run` - Start development server on port 4000

### Code Quality
- `mix compile --warnings-as-errors` - Compile with warnings as errors (ALWAYS use this)
- `mix credo` - Run static code analysis
- `mix dialyzer` - Run type checking
- `mix format` - Format Elixir code
- `./assets/node_modules/.bin/prettier --check ./assets/js` - Check JS formatting
- `./assets/node_modules/.bin/prettier -w ./assets/js` - Format JS code

**CRITICAL RULE: Always compile and test with --warnings-as-errors flag. ALL warnings must be fixed immediately at the exact line numbers reported.**

### Assets
- `mix assets.build` - Build frontend assets
- `mix assets.deploy` - Build and minify assets for production

### Internationalization
- `mix i18n` - Extract translation strings
- **IMPORTANT**: When introducing new `dgettext` keys, always run `mix gettext.extract --merge` and add English translations to the appropriate `.po` files in `priv/gettext/en/LC_MESSAGES/`

## Architecture Overview

This is an Elixir Phoenix LiveView application using a **Systems-based architecture** where functionality is organized into autonomous systems rather than traditional MVC layers.

### Core Architecture Components

#### Systems (`/systems/`)
- **Autonomous modules** containing complete functionality (models, views, logic, routes)
- Each system has optional **features** indicated by files starting with underscore:
  - `_public.ex` - Public API for other systems
  - `_private.ex` - Internal implementation details
  - `_queries.ex` - Database queries and data access
  - `_presenter.ex` - View model presentation logic
  - `_routes.ex` - Phoenix routing for web endpoints
  - `_switch.ex` - Signal routing and event handling
  - `_assembly.ex` - System component assembly
  - `_plug.ex` - HTTP request processing

#### Frameworks (`/frameworks/`)
- **Concept** - Core system abstractions and behaviors
- **Fabric** - LiveView and component utilities (deprecated, being replaced by LiveNest)
- **GreenLight** - Authorization and permissions system
- **Pixel** - UI component library (buttons, forms, cards, etc.)
- **Signal** - Inter-system communication bus
- **Utility** - Common helper modules

#### LiveNest Framework
- **LiveNest** - Modern replacement for Fabric framework
- Internally created Elixir dependency for LiveView utilities
- Designed as open-source framework for broader community use
- Handles LiveView component composition and state management

#### File Naming Conventions
- `*_model.ex` - Ecto schemas and data models
- `*_form.ex` - Form components for data input
- `*_view.ex` - Display components
- `*_page.ex` - LiveView pages
- `*_controller.ex` - Phoenix controllers

### Key Systems
- **Account** - User management, authentication, profiles
- **Assignment** - Research assignments and workflows
- **Project** - Project management and organization
- **Storage** - File storage backends (builtin, AWS, Azure, Yoda)
- **Graphite** - Benchmarking and leaderboards
- **Pool** - Participant pools for studies
- **Crew** - Task management and collaboration
- **Budget** - Financial management and rewards

#### Next Generation Knowledge Systems (Human-AI Collaboration → Global Knowledge Democracy)
These systems form a sophisticated **human-AI collaboration platform** that evolves into a **global knowledge democracy**:

- **Annotation** - Human-readable knowledge layer → Open global knowledge platform
  - **Infinite Flexibility**: Annotations can connect to knowledge graph in indefinite ways
  - **Recipe Organization**: Structured patterns define meaningful knowledge arrangements
  - **Global Commitment**: Natural language knowledge committed to immutable blockchain
  - **Third-Party APIs**: Open access for external developers to build knowledge applications

- **Ontology** - Formal knowledge layer → Open semantic infrastructure
  - Stores AI-formalized concepts, predicates, and logical structures
  - Continuously evolves through AI processing of human annotations
  - **Global Truth Infrastructure**: Immutable blockchain for consensus-validated formal knowledge
  - **Open Semantic APIs**: Third-party access to formal knowledge for innovation ecosystem

- **Onyx** - Human-AI collaboration interface → Public knowledge browser
  - Visual platform for validating AI-synthesized knowledge
  - Real-time visualization of knowledge formalization process
  - **Future**: Tools for citizens to "surf" the state-of-art of science
  - **Democratic Science**: Transform how society accesses scientific knowledge

- **Zircon** - Foundational knowledge population tool → Universal research platform
  - **Primary Knowledge Seeder**: First tool to populate the Annotation/Ontology layers
  - **Universal Research Tool**: Systematic review needed by every researcher
  - **Knowledge Graph Builder**: Transforms literature reviews into formal knowledge
  - **Future**: Foundation for additional research tools populating global knowledge base

### Signal Architecture
Systems communicate through the **Signal framework** for loose coupling:
- Child systems communicate with parents only through Signal
- Direct function calls between systems are discouraged
- Signals are dispatched for state changes and events
- Each system can have a `_switch.ex` to handle incoming signals

### Authorization
Uses **GreenLight** framework with hierarchical permissions:
- Tree-based authorization nodes
- Role assignments at different levels
- Permission inheritance through the tree structure

### Database
- PostgreSQL with Ecto ORM
- Migrations in `/priv/repo/migrations/`
- Models use `use Core, :model` for common functionality

### Frontend
- Phoenix LiveView for reactive UI
- Tailwind CSS for styling
- Custom JavaScript hooks in `/assets/js/`
- Component library in `frameworks/pixel/components/`

### Testing
- Uses ExUnit with custom test cases:
  - `Core.DataCase` for database tests
  - `CoreWeb.ConnCase` for controller/LiveView tests
- Factory functions in `Core.Factories` and system-specific factories
- Mocking with Mox for external dependencies
- Signal testing with `Frameworks.Signal.TestHelper`

## Development Guidelines

### 🚨 CRITICAL ELIXIR RULE #1: ALWAYS USE PATTERN MATCHING 🚨

**THIS IS THE MOST IMPORTANT RULE - NEVER ACCESS DATA WITH DOT NOTATION**

```elixir
# ✅✅✅ ALWAYS DO THIS - Pattern match in function head
def view_model(%{entries: entries, reference_file: %{file: %{name: filename}}}, assigns) do
  # Work with extracted variables
  process_entries(entries)
  create_description(filename)
end

def handle_event("click", _params, %{assigns: %{model: %{status: status}}} = socket) do
  # Work with extracted status
  handle_status(status)
end

# ❌❌❌ NEVER DO THIS - Dot notation access
def view_model(session, assigns) do
  filename = session.reference_file.file.name  # WRONG!
  entries = session.entries  # WRONG!
  status = assigns.model.status  # WRONG!
end
```

**REMEMBER**: If you find yourself writing `variable.field` or `variable.field.nested_field`, STOP and rewrite with pattern matching!

### Elixir Style Rules
- **No alias grouping** - Each alias on separate line
- **Always alias Systems modules** - Use `alias Systems.Paper` then `Paper.Model`, never `Systems.Paper.Model` directly in code
- Prefer single system alias: `alias Systems.Account` then use `Account.Model`
- Follow existing naming patterns and file structures
- **Prefer subfunctions over comments** - When a function is long or needs extensive comments, split it into smaller, well-named functions instead. Function names should be self-documenting and eliminate the need for comments explaining what the code does.
- **Function clause grouping** - All function clauses with the same name and arity must be grouped together. Elixir requires this for pattern matching to work correctly.

```elixir
# ✅ Correct - same name/arity clauses grouped together
def process_data(string) when is_binary(string), do: {:string, string}
def process_data(list) when is_list(list), do: {:list, list}
def process_data(string, opts) when is_binary(string), do: {:string, string, opts}

# ❌ Incorrect - will cause compiler warning
def process_data(string) when is_binary(string), do: {:string, string}
def process_data(string, opts) when is_binary(string), do: {:string, string, opts}  # Wrong: different arity mixed in
def process_data(list) when is_list(list), do: {:list, list}  # Wrong: same arity separated
```

- **Pattern matching enforcement** - This rule is so critical it's been moved to the top as CRITICAL RULE #1. Always pattern match in function heads. Never use dot notation to access nested data.

### Testing Patterns
- Use associations over foreign keys in tests
- Always preload associations before asserting
- Use factory functions for test data creation
- Test both positive and negative cases

### Signal Usage
- Use Signal for inter-system communication
- Document all signals a system sends/receives
- Implement proper error handling for signals
- Test signal handlers in isolation

### System Development
- Keep systems autonomous and loosely coupled
- Use appropriate system features (`_public.ex`, `_queries.ex`, etc.)
- Follow existing patterns for models, forms, views, and pages
- Implement proper authorization using GreenLight

## Bundle System
The application supports different "bundles" (configurations):
- Bundle selection via `.bundle.ex` file in root
- Bundle-specific config in `/bundles/{bundle}/config/`
- Current bundles: `next`, `self`

## Build Warning Fix Rule
**CRITICAL**: When fixing compiler warnings, ALWAYS target the **exact line numbers** specified in the warning message. Never use find-and-replace-all approaches. Be surgical and precise - fix only the problematic lines mentioned in the compiler output.

Example:
```
warning: variable "html" is unused
  │
50 │       {:ok, view, html} = live_isolated(conn, Screening.ImportView, session: session)
  │                   ~~~~
```
Fix ONLY line 50, not all occurrences of similar patterns in the file.

## Test Fixing Workflow
When the user asks to fix multiple failing tests:
1. **Run all tests first** to get current state of failures
2. **Create a todo list** with all failing tests
3. **Present the list** to the user and ask which one to fix
4. **Fix one test at a time** based on user selection
5. **Mark as completed** in todo list after fixing
6. **Re-evaluate failures** when requested - run tests again and update the list
7. **Never assume** which test to fix - always ask the user to choose

## Block Architecture Pattern

### Vision: Page as Stack of Blocks
**Long-term Vision**: A general rendering engine that stacks reusable blocks, where pages become declarative configurations of composable block components. This would enable:
- **Declarative Page Composition**: Pages defined as ordered lists of block configurations
- **Reusable Block Library**: Shared blocks across different LiveViews and systems
- **Dynamic Layout Engine**: Runtime composition and reordering of blocks
- **Configuration-Driven UI**: Pages built through data rather than hardcoded templates

**Current Approach**: Start with blocks tightly coupled to LiveViews as a foundation for this larger vision.

### Block vs Section Terminology
- **Block** = Technical, implementation-focused, granular component for developers
- **Section** = User-facing, semantic grouping concept for end users
- A Section can contain multiple Blocks
- A Block can be fine-grained or coarse-grained
- A Block can be a Section, but a Section is not always a Block
- Blocks are not necessarily noticeable to users as separate entities

### Block Function Components
Use atoms in ViewBuilder to define blocks, with LiveView mapping to render functions:

**ViewBuilder defines self-contained blocks:**
```elixir
def view_model(data, _assigns) do
  blocks = [
    {:header, %{
      title: "Page Title",
      user: current_user
    }},
    {:content, %{
      data: processed_data,
      layout: :grid,
      empty_message: "No data available"
    }},
    {:actions, %{
      buttons: action_buttons
    }}
  ]

  %{blocks: blocks}  # Only blocks needed in view model
end
```

**LiveView renders self-contained blocks:**
```elixir
def render(assigns) do
  ~H"""
  <div class="main-view" data-testid="main-view">
    <%= for {block_type, block_assigns} <- @vm.blocks do %>
      <%= render(block_type, Map.merge(assigns, block_assigns)) %>
    <% end %>
  </div>
  """
end

def render(:header, assigns) do
  ~H"""
  <div data-testid="header-block">
    <h1>{@title}</h1>
    <span>{@user.displayname}</span>
  </div>
  """
end

def render(:content, assigns) do
  ~H"""
  <div data-testid="content-block" class={@layout}>
    <%= if Enum.empty?(@data) do %>
      <p>{@empty_message}</p>
    <% else %>
      <%= for item <- @data do %>
        <div>{item.name}</div>
      <% end %>
    <% end %>
  </div>
  """
end

def render(:actions, assigns) do
  ~H"""
  <div data-testid="actions-block">
    <Button.dynamic_bar buttons={@buttons} />
  </div>
  """
end
```

### When to Use Block Components
- **DO** use blocks for complex, multi-section pages that benefit from composition
- **DON'T** force blocks for simple single-purpose views
- **DO** keep blocks tightly coupled to their parent LiveView when appropriate
- **DON'T** always move blocks to system-level `_html.ex` files
- **DON'T** always add blocks as components to Pixel framework
- **CONSIDER** blocks as an intermediate step between inline rendering and full componentization

### Flexible Block Architecture
Support both patterns based on complexity:

**Simple views**: Use direct vm properties
```elixir
# ViewBuilder for simple case
%{
  title: "Simple Page",
  data: processed_data,
  buttons: action_buttons
}

# LiveView renders directly
def render(assigns) do
  ~H"""
  <div>
    <h1>{@vm.title}</h1>
    <div>{render_data(@vm.data)}</div>
    <Button.dynamic_bar buttons={@vm.buttons} />
  </div>
  """
end
```

**Complex views**: Use block composition
```elixir
# ViewBuilder with blocks for complex layouts
%{
  user_name: current_user.name,  # Shared across blocks
  blocks: [
    {:header, %{title: "Complex Page"}},
    {:content, %{data: processed_data}},
    {:actions, %{buttons: action_buttons}}
  ]
}

# Blocks can access both vm and block_assigns
def render_block(%{block: :header, vm: vm} = assigns) do
  ~H"""
  <div>
    <h1>{@title}</h1>
    <span>Welcome {vm.user_name}</span>  <!-- From vm -->
  </div>
  """
end
```

### Block Naming in Tests
Use `data-testid="*-block"` for technical implementation components:
```elixir
assert view |> has_element?("[data-testid='errors-block']")
assert view |> has_element?("[data-testid='content-block']")
```

### Block Component Benefits
- **Maintainability**: Easier to read and modify complex render functions
- **Testability**: Individual blocks can be tested in isolation
- **Reusability**: Blocks can be reused within the same LiveView
- **Encapsulation**: Keep related rendering logic together
- **Flexibility**: Intermediate step between monolithic render and full componentization
- **Future-Proof**: Foundation for eventual general rendering engine

### Evolution Path: From Coupled to Composable
1. **Phase 1 (Current)**: Atom-based block configuration with LiveView mapping
2. **Phase 2**: Extract render functions to BlockFactory modules
3. **Phase 3**: Block registry and cross-system block sharing
4. **Phase 4**: General rendering engine with declarative block stacking

Example future vision:
```elixir
# Current: ViewBuilder defines block types
blocks = [
  {:header, %{title: @title, user: @user}},
  {:content, %{data: @data, layout: :grid}},
  {:actions, %{buttons: @buttons}}
]

# Future: Cross-system block factory
def render_block_by_type(:header, assigns),
  do: Systems.Common.BlockFactory.render_header_block(assigns)
```

## Block Configuration
- **Use vm properties directly into the block assigns**

## Signal Framework Patterns and Best Practices

### Understanding Signal Architecture
The Signal framework provides event-driven communication between systems, but has important characteristics to understand:

#### Process Isolation
- **Signals are process-specific**: Signal handlers configured with `Process.get/put` only affect the current process
- **LiveView processes are separate**: Each LiveView runs in its own process and doesn't inherit test signal isolation
- **Database transactions may use different processes**: Operations within `Repo.transaction` may run in connection pool processes

#### Multi Operations and Signal Keys
```elixir
# ✅ CORRECT: Multi operation name matches expected signal key
multi
|> Multi.update(:paper_reference_file, changeset)
|> Signal.Public.multi_dispatch({:paper_reference_file, :updated})

# ❌ WRONG: Operation name doesn't match expected key
multi
|> Multi.update(:archive_file, changeset)  # Creates :archive_file key
|> Signal.Public.multi_dispatch({:paper_reference_file, :updated})  # Handler expects :paper_reference_file
```

#### Composable Multi Functions with Signals
```elixir
# Create reusable Multi-based functions
def multi_archive_reference_file(multi, reference_file_id) do
  reference_file = Repo.get!(Paper.ReferenceFileModel, reference_file_id)

  multi
  |> Multi.update(:paper_reference_file,
      Paper.ReferenceFileModel.changeset(reference_file, %{status: :archived}))
  |> Signal.Public.multi_dispatch({:paper_reference_file, :updated},
      name: :dispatch_archive_signal)  # Unique name to avoid conflicts
end

# Compose multiple operations atomically
def abort_import!(session) do
  Multi.new()
  |> Paper.Public.multi_abort_import_session(session)
  |> Paper.Public.multi_archive_reference_file(session.reference_file_id)
  |> Repo.transaction()
end
```

#### Signal Dispatch Best Practices
1. **Always use unique operation names** when calling `multi_dispatch` multiple times
2. **Handle unhandled signals gracefully**:
```elixir
# In Signal.Public.multi_dispatch
case dispatch(signal, message) do
  :ok -> {:ok, message}
  {:error, :unhandled_signal} ->
    # Don't fail transaction for unhandled signals
    {:ok, message}
  error -> error
end
```

3. **Order matters for database operations**: Archive/update data BEFORE dispatching signals that trigger view updates

#### Signal Chaining
Signals can chain through `{:continue, key, value}`:
```elixir
def intercept({:paper_reference_file, :updated}, message) do
  # Process and continue with new signal
  {:continue, :zircon_screening_tool, tool}
end
# This triggers {:zircon_screening_tool, {:paper_reference_file, :updated}}
```

#### Common Signal Patterns
```elixir
# Standard CRUD signals
{:model_name, :created}
{:model_name, :updated}
{:model_name, :deleted}

# Status change signals
{:paper_ris_import_session, :parsing}
{:paper_ris_import_session, :processing}
{:paper_ris_import_session, :prompting}
{:paper_ris_import_session, :aborted}

# View update signals
{:embedded_live_view, ModuleName}
{:page, ModuleName}
```

### Debugging Signals
- Use logging to trace signal flow: Signals log with blue ANSI color
- Check for "Unhandled signal" warnings in logs
- Verify Multi operation names match expected signal message keys
- Remember signals cross process boundaries - test isolation may not work as expected

## Debugging Approach for Bug Fixes

When trying to fix a bug, you have two options:

### Option 1: Create a Failing Test (Preferred)
Create a test that reproduces the edge case and fails, with debug logging to understand the issue:
```elixir
test "abort clears file in empty prompting case", %{conn: conn, tool: tool} do
  # Setup the exact edge case
  import_session = Factories.insert!(:paper_ris_import_session, %{
    phase: :prompting,
    entries: [],  # Empty results - the edge case
    errors: []
  })

  IO.puts("Initial state: #{inspect(import_session)}")

  # Call the function that should work
  Zircon.Public.abort_import!(import_session)

  # Add debugging to see what actually happened
  updated_file = Repo.get!(Paper.ReferenceFileModel, file_id)
  IO.puts("File status after abort: #{updated_file.status}")

  # This assertion should fail if bug exists
  assert updated_file.status == :archived
end
```

### Option 2: Add Debug Logging for Browser Testing
If it's absolutely impossible to make a test case (e.g., complex LiveView interactions), add debug logging and ask the user to run in the browser:
```elixir
def abort_import!(session) do
  IO.puts("\n=== ABORT_IMPORT! DEBUG ===")
  IO.puts("Session: #{inspect(session)}")
  IO.puts("Phase: #{session.phase}")
  IO.puts("Entries: #{inspect(session.entries)}")

  result = Multi.new()
  |> Paper.Public.multi_abort_import_session(session)
  |> Paper.Public.multi_archive_reference_file(session.reference_file_id)
  |> Repo.transaction()

  IO.puts("Transaction result: #{inspect(result)}")

  case result do
    {:ok, changes} ->
      IO.puts("Success! Changes: #{inspect(Map.keys(changes))}")
      :ok
    {:error, operation, error, _} ->
      IO.puts("FAILED at #{operation}: #{inspect(error)}")
      raise "Failed to abort import: #{inspect(error)}"
  end
end
```

Then ask: "Can you test this in the browser and share the logs?"

### Important: Always Try Option 1 First
- Tests are repeatable and catch regressions
- Tests can be debugged more easily
- Tests document the expected behavior
- Only resort to browser debugging when test environment truly can't reproduce the issue