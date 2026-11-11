# `Systems.Assignment.ToolViewFactory`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/tool_view_factory.ex#L1)

Utility for preparing tool live views in Assignment/Crew context.

Converts ToolModel to ToolView via naming convention and prepares
LiveNest elements. Each ToolView uses ViewBuilder pattern for view models.

Also extends context with tool-specific data (e.g., Alliance url and description).

# `prepare`

Prepares a tool live view element with CrewTaskContext.

Uses naming convention: ToolModel → ToolView
Passes CrewTaskContext in session; ToolView uses ViewBuilder + LiveContext.

# `prepare_modal`

Prepares a tool live view wrapped in a modal with CrewTaskContext.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
