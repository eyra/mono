defmodule Systems.Assignment.ToolViewFactory do
  @moduledoc """
  Utility for preparing tool live views in Assignment/Crew context.

  Converts ToolModel to ToolView via naming convention and prepares
  LiveNest elements. Each ToolView uses ViewBuilder pattern for view models.

  Also extends context with tool-specific data (e.g., Alliance url and description).
  """

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Workflow

  @doc """
  Prepares a tool live view element with CrewTaskContext.

  Uses naming convention: ToolModel → ToolView
  Passes CrewTaskContext in session; ToolView uses ViewBuilder + LiveContext.
  """
  def prepare(tool_ref, task_context) do
    tool = Workflow.ToolRefModel.tool(tool_ref)
    view_module = tool_model_to_view_module(tool.__struct__)
    task_context = extend_context_for_tool(tool, task_context)

    LiveNest.Element.prepare_live_view(
      "tool_view",
      view_module,
      live_context: task_context
    )
  end

  @doc """
  Prepares a tool live view wrapped in a modal with CrewTaskContext.
  """
  def prepare_modal(tool_ref, task_context, modal_id) do
    tool = Workflow.ToolRefModel.tool(tool_ref)
    view_module = tool_model_to_view_module(tool.__struct__)
    task_context = extend_context_for_tool(tool, task_context)

    LiveNest.Modal.prepare_live_view(
      modal_id,
      view_module,
      style: :full,
      session: [live_context: task_context]
    )
  end

  # Naming convention: Replace "ToolModel" suffix with "ToolView"
  defp tool_model_to_view_module(tool_module) do
    tool_module
    |> Module.split()
    |> List.update_at(-1, fn name -> String.replace(name, "ToolModel", "ToolView") end)
    |> Module.concat()
  end

  # Alliance tool: add url (with participant) and description
  defp extend_context_for_tool(%Systems.Alliance.ToolModel{url: base_url}, context) do
    participant = context.data[:participant] || ""

    url = build_alliance_url(base_url, participant)
    description = dgettext("eyra-alliance", "tool.description")

    LiveContext.extend(context, %{url: url, description: description})
  end

  # Other tools: no additional context needed
  defp extend_context_for_tool(_tool, context), do: context

  defp build_alliance_url(base_url, ""), do: base_url

  defp build_alliance_url(base_url, participant) do
    "#{base_url}?participant=#{participant}"
  end
end
