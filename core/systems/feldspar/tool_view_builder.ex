defmodule Systems.Feldspar.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  @doc """
  Builds view model for Feldspar tool view.

  ## Parameters
  - tool: The Feldspar tool model
  - assigns: Contains title and icon from CrewTaskContext
  """
  def view_model(tool, %{title: title, icon: icon} = assigns) do
    {app_view, error} = build_app_view(tool)
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

  defp build_app_view(%{archive_ref: nil}) do
    {nil, dgettext("eyra-feldspar", "tool.archive.not.configured")}
  end

  defp build_app_view(%{id: id, archive_ref: archive_ref}) do
    {LiveNest.Element.prepare_live_component(
       "feldspar_app_view_#{id}",
       Systems.Feldspar.AppView,
       key: "feldspar_tool_#{id}",
       url: archive_ref <> "/index.html",
       locale: Gettext.get_locale(CoreWeb.Gettext)
     ), nil}
  end

  defp normalize_icon(nil), do: nil
  defp normalize_icon(icon) when is_binary(icon), do: String.downcase(icon)
  defp normalize_icon(icon) when is_atom(icon), do: icon |> Atom.to_string() |> String.downcase()
end
