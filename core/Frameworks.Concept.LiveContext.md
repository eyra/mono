# `Frameworks.Concept.LiveContext`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/live_context.ex#L1)

Context container that holds shared state across a view hierarchy.

Backed by a map for maximum flexibility - can store any data at any level.
All contexts are stored under the "live_context" session key.

## Two Context Patterns

LiveContext supports two patterns for managing data ownership:

### Pattern 1: Parent-Managed (Full Objects)

Context contains full objects. Parent manages all data updates, child views are passive consumers.

    context = LiveContext.new(%{
      assignment: assignment,     # Full object
      crew: crew,                 # Full object
      current_user: user,         # Full object
      user_state_data: data
    })

- **Ownership**: Parent owns the data lifecycle
- **Updates**: Parent updates context, child re-renders
- **Observatory**: Optional (updates redundant)
- **Use when**: Tight parent-child coupling, parent controls all state

### Pattern 2: Child-Managed (IDs)

Context contains IDs. Child views fetch and manage their own models independently.

    context = LiveContext.new(%{
      assignment_id: 123,         # Just ID
      crew_id: 456,               # Just ID
      user_id: 789,               # Just ID
      user_state_data: data
    })

- **Ownership**: Child owns the data lifecycle
- **Updates**: Observatory signals child directly
- **Observatory**: Required (child manages updates)
- **Use when**: Autonomous child views, independent update cycles

## Usage

Embedded live views declare their dependencies:

    on_mount({MicaWeb.Live.Hook.Context, [:crew, :current_user]})

The hook extracts these from context and assigns to socket.assigns.

## LiveView Responsibilities with IDs

When context contains IDs (Pattern 2), the LiveView must fetch the full object:

    # In LiveView mount or get_model
    def get_model(:not_mounted_at_router, _session, %{assigns: %{crew_id: crew_id}}) do
      Crew.Public.get!(crew_id)  # LiveView fetches, not LiveContext
    end

This keeps LiveContext generic and dependency-free.

## Retrieval Strategy

Simple value lookup:
1. Check context data
2. Fallback to socket.assigns (populated by Observatory or parent)

## Future: Preloading Pattern (Not Yet Implemented)

Similar to Ecto associations, context could support both ID and object:

    context = LiveContext.new(%{
      assignment_id: 123,         # Always present
      assignment: assignment      # Optional "preloaded" object
    })

Then `retrieve(:assignment, ...)` would:
1. Return full object if present (no fetch needed)
2. Fetch by assignment_id if object is nil
3. Cache in socket.assigns for subsequent calls

This avoids repetitive database calls while maintaining the ID-based pattern.

# `extend`

Extends a parent context with new data, inheriting all parent values.

This enables automatic flow of common context data (timezone, current_user, user_state_data)
through the view hierarchy without explicit pass-through at each level.

## Examples

    # Parent context has timezone, current_user, user_state_data
    parent_context = LiveContext.new(%{
      timezone: "UTC",
      current_user: user,
      user_state_data: %{tab: "overview"}
    })

    # Child extends with only new data - inherits everything else
    child_context = LiveContext.extend(parent_context, %{
      assignment_id: 123,
      crew_id: 456
    })

    # Result: child_context.data == %{
    #   timezone: "UTC",           # inherited
    #   current_user: user,        # inherited
    #   user_state_data: %{...},   # inherited
    #   assignment_id: 123,        # new
    #   crew_id: 456               # new
    # }

    # When no parent context exists (top level), creates new context
    context = LiveContext.extend(nil, %{timezone: "UTC"})

# `missing_dependencies`

Returns list of missing dependencies that are not available in context.

Useful for error reporting when `ready?/2` returns false.

# `new`

Creates a new context with the given data map.

# `ready?`

Check if context can provide all specified dependencies.

Returns true if all dependencies exist in context data or socket.assigns.
Supports tuple dependencies like `{:user_state, :chapter_id}`.

# `retrieve`

Retrieve a dependency from context.

Simply returns the value from context data or socket.assigns.
No database fetching - LiveViews are responsible for fetching if they receive IDs.

## Examples

    # Pattern 1: Full object in context
    retrieve(ctx, :assignment, socket)  # Returns assignment from data

    # Pattern 2: ID in context, LiveView fetches
    retrieve(ctx, :assignment_id, socket)  # Returns ID
    # LiveView then: Assignment.Public.get!(assignment_id)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
