# `Systems.Assignment.CrewTaskHelpers`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/crew_task_helpers.ex#L1)

# `socket`

```elixir
@type socket() :: Phoenix.LiveView.Socket.t()
```

# `handle_tool_completed`

```elixir
@callback handle_tool_completed(socket()) :: socket()
```

# `handle_tool_initialized`

```elixir
@callback handle_tool_initialized(socket()) :: socket()
```

# `build_work_items`

Builds work_items list from assignment for the given user.
Each work_item is a tuple {workflow_item, task}.

# `get_icon`

# `get_participant`

Get participant from panel_info (external panel) or crew member's public_id.

Looks for panel_info in multiple locations:
1. Directly in assigns[:panel_info]
2. In the live_context.data[:panel_info]

# `map_item`

# `recovery_context`

# `singleton?`

# `task_status`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
