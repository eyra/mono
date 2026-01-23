defmodule Systems.Feldspar.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  @doc """
  Builds view model for Feldspar tool view.

  ## Parameters
  - tool: The Feldspar tool model
  - assigns: Contains title and icon from CrewTaskContext
  """
  def view_model(tool, %{title: title, icon: icon} = assigns) do
    {app_view, error} = build_app_view(tool, assigns)
    loading = Map.get(assigns, :loading, false)

    %{
      tool: tool,
      title: title,
      icon: normalize_icon(icon),
      description: dgettext("eyra-feldspar", "tool.description"),
      button: build_button(loading),
      app_view: app_view,
      error: error
    }
  end

  defp build_button(loading) do
    %{
      action: %{type: :send, event: "start"},
      face: %{
        type: :primary,
        label: dgettext("eyra-feldspar", "tool.button"),
        loading: loading
      }
    }
  end

  defp build_app_view(%{archive_ref: nil}, _assigns) do
    {nil, dgettext("eyra-feldspar", "tool.archive.not.configured")}
  end

  defp build_app_view(%{id: id, archive_ref: archive_ref}, assigns) do
    {LiveNest.Element.prepare_live_component(
       "feldspar_app_view_#{id}",
       Systems.Feldspar.AppView,
       key: "feldspar_tool_#{id}",
       url: archive_ref <> "/index.html",
       locale: Gettext.get_locale(CoreWeb.Gettext),
       upload_context: build_upload_context(assigns)
     ), nil}
  end

  defp build_upload_context(assigns) do
    %{
      assignment_id: Map.get(assigns, :assignment_id),
      task: Map.get(assigns, :workflow_item_id),
      participant: Map.get(assigns, :participant),
      group: normalize_icon(Map.get(assigns, :icon)),
      panel_info: Map.get(assigns, :panel_info)
    }
  end

  defp normalize_icon(nil), do: nil
  defp normalize_icon(icon) when is_binary(icon), do: String.downcase(icon)
  defp normalize_icon(icon) when is_atom(icon), do: icon |> Atom.to_string() |> String.downcase()
end
