defmodule Systems.Manual.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Manual

  @doc """
  Builds view model for Manual tool view.

  ## Parameters
  - tool: The Manual tool model
  - assigns: Contains live_context with title, current_user, user_state from CrewTaskContext
  """
  def view_model(tool, %{live_context: context} = assigns) do
    %{title: title} = assigns

    %{
      manual: tool,
      title: title,
      manual_view: build_manual_view(tool, context)
    }
  end

  defp build_manual_view(%{manual_id: manual_id}, %LiveContext{data: data} = context) do
    # Preserve presentation from parent context, default to :modal
    presentation = Map.get(data, :presentation, :modal)

    context =
      LiveContext.extend(context, %{
        manual_id: manual_id,
        presentation: presentation,
        user_state_namespace: [:manual, manual_id]
      })

    LiveNest.Element.prepare_live_view(
      "manual_view",
      Manual.View,
      live_context: context
    )
  end
end
