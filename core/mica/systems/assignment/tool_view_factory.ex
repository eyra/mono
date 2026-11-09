defmodule Systems.Assignment.ToolViewFactory do
  @moduledoc """
  Utility for preparing tool live views in Assignment/Crew context.

  Converts ToolModel to ToolView via naming convention and prepares
  LiveNest elements. Each ToolView uses ViewBuilder pattern for view models.

  Also extends context with tool-specific data (e.g., Alliance url and description).
  """

  use Gettext, backend: MicaWeb.Gettext

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
    task_context = extend_context_for_tool(tool, tool_ref, task_context)

    MicaWeb.Live.Element.prepare_live_view(
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
    task_context = extend_context_for_tool(tool, tool_ref, task_context)

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
  defp extend_context_for_tool(%Systems.Alliance.ToolModel{url: base_url}, _tool_ref, context) do
    participant = context.data[:participant] || ""

    url = build_alliance_url(base_url, participant)
    description = dgettext("eyra-alliance", "tool.description")

    LiveContext.extend(context, %{url: url, description: description})
  end

  # Feldspar tool: start screen description of a template added by the SaaS, nil for the default
  defp extend_context_for_tool(%Systems.Feldspar.ToolModel{}, %{special: special}, context) do
    description = Systems.Assignment.TemplateExtension.tool_description(special)
    LiveContext.extend(context, %{description: description})
  end

  # Other tools: no additional context needed
  defp extend_context_for_tool(_tool, _tool_ref, context), do: context

  defp build_alliance_url(base_url, ""), do: base_url

  defp build_alliance_url(base_url, participant) do
    "#{base_url}?participant=#{participant}"
  end
end
