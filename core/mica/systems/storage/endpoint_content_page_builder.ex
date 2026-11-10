defmodule Systems.Storage.EndpointContentPageBuilder do
  use Gettext, backend: MicaWeb.Gettext
  import Frameworks.Utility.List

  alias Frameworks.Concept
  alias Systems.Storage

  def view_model(
        %{id: id} = endpoint,
        %{branch: branch} = assigns
      ) do
    show_errors = true
    breadcrumbs = Concept.Branch.hierarchy(branch)
    tabs = create_tabs(endpoint, show_errors, assigns)
    title = Concept.Branch.name(branch, :self)

    %{
      id: id,
      title: title,
      breadcrumbs: breadcrumbs,
      tabs: tabs,
      actions: [],
      show_errors: show_errors,
      active_menu_item: :projects
    }
  end

  defp get_tab_keys(endpoint) do
    special = Storage.EndpointModel.special_field(endpoint)

    []
    |> append_if(:settings, special != :builtin)
    |> append_if(:participants, special == :builtin)
    |> append_if(:data, special == :builtin)
  end

  defp create_tabs(
         endpoint,
         show_errors,
         assigns
       ) do
    get_tab_keys(endpoint)
    |> Enum.map(&create_tab(&1, endpoint, show_errors, assigns))
  end

  defp create_tab(
         :settings,
         endpoint,
         show_errors,
         %{fabric: fabric} = _assigns
       ) do
    ready? = true

    child =
      Fabric.prepare_child(fabric, :settings_view, Storage.EndpointSettingsView, %{
        endpoint: endpoint
      })

    %{
      id: :settings_view,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-storage", "tabbar.item.settings"),
      forward_title: dgettext("eyra-storage", "tabbar.item.settings.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :data,
         endpoint,
         show_errors,
         %{branch: branch, fabric: fabric, timezone: timezone} = _assigns
       ) do
    ready? = true
    branch_name = Concept.Branch.name(branch, :parent)

    child =
      Fabric.prepare_child(fabric, :data_view, Storage.EndpointDataView, %{
        endpoint: endpoint,
        branch_name: branch_name,
        timezone: timezone
      })

    %{
      id: :data_view,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-storage", "tabbar.item.data"),
      forward_title: dgettext("eyra-storage", "tabbar.item.data.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :participants,
         endpoint,
         show_errors,
         %{fabric: fabric, timezone: timezone} = _assigns
       ) do
    child =
      Fabric.prepare_child(fabric, :participants_view, Storage.EndpointParticipantsView, %{
        endpoint: endpoint,
        timezone: timezone
      })

    %{
      id: :participants_view,
      ready: true,
      show_errors: show_errors,
      title: dgettext("eyra-storage", "tabbar.item.participants"),
      forward_title: dgettext("eyra-storage", "tabbar.item.participants.forward"),
      type: :fullpage,
      child: child
    }
  end
end
