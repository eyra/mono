# LiveNest & LiveHooks Architecture Guide

This document captures patterns for building LiveView hierarchies using LiveNest and the CoreWeb hook system.

## Two Types of LiveViews

### Routed LiveView (Top-Level Page)

A **Routed LiveView** is mounted directly by the router. It:
- Has a URL route in the router
- Receives `params` from the URL
- Gets `current_user` and other data from session via hooks
- Does NOT use LiveContext (it IS the context source)
- Creates LiveContext for its embedded children

```elixir
defmodule Systems.MySystem.ContentPage do
  use CoreWeb, :live_view  # or use Systems.Content.Composer, :some_layout

  # Routed views get params and session
  def get_model(params, _session, _socket) do
    MySystem.Public.get!(params["id"])
  end

  @impl true
  def mount(_params, _session, socket) do
    # current_user already in assigns from User hook
    {:ok, socket}
  end
end
```

### Embedded LiveView (Child View)

An **Embedded LiveView** is rendered inside a parent LiveView. It:
- Has NO URL route
- Receives data via LiveContext from parent
- Declares `dependencies/0` to extract from LiveContext
- Uses `:not_mounted_at_router` as first argument

```elixir
defmodule Systems.MySystem.MyView do
  use CoreWeb, :embedded_live_view

  # Declare what to extract from LiveContext
  def dependencies(), do: [:current_user, :locale, :some_data]

  # First arg is :not_mounted_at_router (not params)
  def get_model(:not_mounted_at_router, _session, %{assigns: %{some_id: id}}) do
    MySystem.Public.get!(id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end
end
```

## The Key Difference: Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        ROUTED LIVEVIEW                          │
│  (ContentPage, ConfigPage, etc.)                                │
│                                                                 │
│  Data sources:                                                  │
│  - URL params → get_model(params, session, socket)              │
│  - Session → current_user, locale via hooks                     │
│  - Database → fetched in get_model or ViewBuilder               │
│                                                                 │
│  Creates LiveContext for children:                              │
│  LiveContext.new(%{current_user: user, locale: locale, ...})    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ LiveContext passed via
                              │ LiveNest.Element.prepare_live_view
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       EMBEDDED LIVEVIEW                         │
│  (MyView, SystemView, etc.)                                     │
│                                                                 │
│  Data sources:                                                  │
│  - LiveContext → extracted via dependencies()                   │
│  - Database → fetched in get_model using context data           │
│                                                                 │
│  def dependencies(), do: [:current_user, :some_id]              │
│  # These are extracted from LiveContext into socket.assigns     │
└─────────────────────────────────────────────────────────────────┘
```

## Hook Execution Order

When a LiveView mounts, hooks execute in this order:
1. **Base** - Basic setup
2. **User** - Assigns `current_user` from session
3. **Timezone** - Assigns timezone
4. **Context** - Extracts dependencies from LiveContext into assigns (embedded only)
5. **Model** - Calls `get_model/3` to fetch the model
6. **Observatory** - Builds view model via Presenter, assigns `vm`
7. **mount/3** - Your LiveView's mount callback (runs LAST)

**Key insight**: By the time `mount/3` runs, `@vm` is already built and available.

## The MVVM Pattern

Observatory is the orchestrator that connects LiveView, Presenter, and ViewBuilder:

```
┌─────────────────┐
│    LiveView     │
│ (defines module,│
│  renders @vm)   │
└─────────────────┘
        │
        │ on_mount hook
        ▼
┌─────────────────────────────────────┐
│           OBSERVATORY               │
│  (Hook that orchestrates vm build)  │
└─────────────────────────────────────┘
        │                       ▲
        │ calls                 │ returns vm map
        ▼                       │
┌─────────────────┐             │
│    Presenter    │             │
│ (routes to      │             │
│  ViewBuilder)   │             │
└─────────────────┘             │
        │                       │
        │ delegates             │ returns vm map
        ▼                       │
┌─────────────────┐             │
│   ViewBuilder   │ ────────────┘
│  (builds vm)    │
└─────────────────┘
```

**Flow:**
1. **LiveView** mounts, triggering hooks
2. **Observatory** (hook) receives the LiveView module and model from earlier hooks
3. **Observatory** calls **Presenter** with `view_model(LiveViewModule, model, assigns)`
4. **Presenter** delegates to the correct **ViewBuilder** based on the module
5. **ViewBuilder** builds and returns the `vm` map to Presenter
6. **Presenter** returns the `vm` map to Observatory
7. **Observatory** assigns `vm` to socket, available as `@vm` in LiveView

**Components:**
- **Observatory**: Hook that orchestrates the view model build process
- **Presenter**: Routes `view_model/3` calls to the appropriate ViewBuilder
- **ViewBuilder**: Pure functions that transform model + assigns into a view model map
- **LiveView**: Handles events and renders the view model (`@vm`)

---

## Routed LiveView Example

### The Page (Router-Mounted)

```elixir
defmodule Systems.MySystem.ContentPage do
  use Systems.Content.Composer, {:management_page, :live_nest}

  # Gets URL params - this is a ROUTED view
  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    MySystem.Public.get!(id, MySystem.Model.preload_graph(:full))
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(initial_tab: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.management_page
      title={@vm.title}
      tabs={@vm.tabs}
      ...
    />
    """
  end
end
```

### The PageBuilder (Creates LiveContext)

```elixir
defmodule Systems.MySystem.ContentPageBuilder do
  alias Frameworks.Concept.LiveContext

  def view_model(model, %{current_user: user} = assigns) do
    locale = Map.get(assigns, :locale, :en)

    # Create LiveContext for embedded children
    live_context = LiveContext.new(%{
      current_user: user,
      locale: locale
    })

    %{
      title: model.name,
      tabs: create_tabs(model, live_context)
    }
  end

  defp create_tabs(model, context) do
    # Extend context with tab-specific data
    child_context = LiveContext.extend(context, %{
      model_id: model.id,
      items: model.items
    })

    element = LiveNest.Element.prepare_live_view(
      "details_view",
      MySystem.DetailsView,
      live_context: child_context
    )

    [%{id: :details, title: "Details", element: element}]
  end
end
```

---

## Embedded LiveView Example

### The View (Embedded in Parent)

```elixir
defmodule Systems.MySystem.DetailsView do
  use CoreWeb, :embedded_live_view

  # Declare dependencies to extract from LiveContext
  def dependencies(), do: [:current_user, :locale, :model_id, :items]

  # First arg is :not_mounted_at_router (NOT params)
  def get_model(:not_mounted_at_router, _session, %{assigns: %{model_id: id}}) do
    # model_id was extracted from LiveContext by the Context hook
    MySystem.Public.get!(id)
  end

  # For views without a real model
  def get_model(:not_mounted_at_router, _session, _assigns) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    # vm is already built by Observatory hook
    {:ok, socket}
  end

  @impl true
  def handle_event("some_action", _params, socket) do
    {:noreply, socket |> do_something()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="details-view">
      <Text.title2><%= @vm.title %></Text.title2>
      <%= for item <- @vm.items do %>
        <div><%= item.name %></div>
      <% end %>
    </div>
    """
  end
end
```

### The ViewBuilder

```elixir
defmodule Systems.MySystem.DetailsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(model, assigns) do
    # Use Map.get with defaults for safety
    locale = Map.get(assigns, :locale, :en)
    items = Map.get(assigns, :items, [])

    %{
      title: dgettext("my-domain", "details.title"),
      model_name: model.name,
      items: transform_items(items, locale)
    }
  end
end
```

### Register in Presenter

```elixir
defmodule Systems.MySystem.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.MySystem

  @impl true
  def view_model(MySystem.ContentPage, model, assigns) do
    MySystem.ContentPageBuilder.view_model(model, assigns)
  end

  def view_model(MySystem.DetailsView, model, assigns) do
    MySystem.DetailsViewBuilder.view_model(model, assigns)
  end
end
```

---

## Updating View Models

### FORBIDDEN: rebuild_vm

Never use `rebuild_vm` - it's an anti-pattern.

### CORRECT: update_view_model

```elixir
def handle_event("filter_changed", %{"filter" => filter}, socket) do
  {:noreply,
   socket
   |> assign(active_filter: filter)
   |> update_view_model()}  # Re-runs ViewBuilder with new assigns
end
```

The `update_view_model/1` function:
1. Takes current socket assigns
2. Calls Presenter to get new vm from ViewBuilder
3. Assigns the new vm to socket

---

## Modals with LiveNest

### Preparing Modals in ViewBuilder

```elixir
# In ViewBuilder
def build_entity_modal(entity, user) do
  LiveNest.Modal.prepare_live_component(
    "entity_form",           # id
    EntityFormComponent,     # module
    params: [                # params passed to component's update/2
      entity: entity,
      user: user
    ],
    style: :compact          # :compact, :default, etc.
  )
end
```

### Presenting Modals in LiveView

```elixir
def handle_event("create_entity", _, %{assigns: %{current_user: user}} = socket) do
  modal = MyViewBuilder.build_entity_modal(nil, user)
  {:noreply, socket |> present_modal(modal)}
end
```

### Modal Component Requirements

The component receives params as direct assigns:

```elixir
defmodule EntityFormComponent do
  use CoreWeb, :live_component

  @impl true
  def update(%{id: id, entity: entity, user: user}, socket) do
    # params from Modal.prepare_live_component are spread here
    {:ok, socket |> assign(id: id, entity: entity, user: user)}
  end
end
```

**Note**: Use `params:` (keyword list) not `props:` (map) in `prepare_live_component`.

---

## Testing

### Testing Routed LiveViews

```elixir
test "renders page", %{conn: conn} do
  entity = Factories.insert!(:entity)
  {:ok, view, html} = live(conn, ~p"/entity/#{entity.id}")
  assert html =~ entity.name
end
```

### Testing Embedded Views in Isolation

```elixir
test "renders view", %{conn: conn} do
  session = %{
    "live_context" => %Frameworks.Concept.LiveContext{
      data: %{
        current_user: user,
        locale: :en,
        model_id: 123,
        items: [item1, item2]
      }
    }
  }

  {:ok, view, html} = live_isolated(conn, MySystem.DetailsView, session: session)
  assert html =~ "Expected content"
end
```

### Testing Embedded Views Within Parent

```elixir
test "embedded view receives events", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/parent/page")

  # Find the embedded child view by its element ID
  child_view = find_live_child(view, "details_view")

  # Send event to child
  render_click(child_view, "some_action")

  # Assert on parent (modals render in parent)
  assert render(view) =~ "Modal content"
end
```

---

## Common Patterns

### Locale Handling

```elixir
# ViewBuilder - always use Map.get with default
locale = Map.get(assigns, :locale, :en)

# Dependencies - include :locale if needed for embedded views
def dependencies(), do: [:locale, :current_user]
```

### User State Dependencies

```elixir
# For scoped user state
def dependencies(), do: [{:user_state, :chapter_id}, {:user_state, [:key1, :key2]}]
```

### Singleton Models

For views without a real database model:

```elixir
def get_model(:not_mounted_at_router, _session, _assigns) do
  Systems.Observatory.SingletonModel.instance()
end
```

---

## Quick Reference: Routed vs Embedded

| Aspect | Routed LiveView | Embedded LiveView |
|--------|-----------------|-------------------|
| Use macro | `use CoreWeb, :live_view` | `use CoreWeb, :embedded_live_view` |
| Router entry | Yes | No |
| get_model first arg | `params` (map) | `:not_mounted_at_router` |
| mount first arg | `params` (map) | `:not_mounted_at_router` |
| Data source | Session + URL params | LiveContext |
| dependencies/0 | Not used | Required |
| Creates LiveContext | Yes (for children) | No (receives it) |

---

## Migration Checklist: Fabric to LiveNest

When migrating a component from Fabric:

1. [ ] Remove `compose_child/2` calls
2. [ ] Remove `@impl true def compose/2` callbacks
3. [ ] Replace `.child` in templates with direct component usage
4. [ ] Remove `fabric` from assigns pattern matching
5. [ ] Use `LiveNest.Modal.prepare_live_component` with `params:` (not `props:`)
6. [ ] Update tests to use `find_live_child/2` for embedded views
7. [ ] Ensure component's `update/2` expects params as direct assigns

## Key Differences from Fabric

| Fabric | LiveNest |
|--------|----------|
| `compose_child(:name)` | Direct component in template |
| `.child name={:x} fabric={@fabric}` | `<.live_component module={X} .../>` |
| `@fabric` in assigns | Not needed |
| `fabric_event` handling | Standard LiveView events |
| `props: %{}` | `params: []` (keyword list) |
