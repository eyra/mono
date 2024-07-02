defmodule Systems.Storage.EndpointContentPageBuilder do
  import CoreWeb.Gettext
  import Frameworks.Utility.List

  alias CoreWeb.UI.Timestamp
  alias Systems.Storage

  def view_model(
        %{id: id} = endpoint,
        assigns
      ) do
    show_errors = false
    tabs = create_tabs(endpoint, show_errors, assigns)

    %{
      id: id,
      title: get_title(endpoint),
      tabs: tabs,
      actions: [],
      show_errors: show_errors,
      active_menu_item: :projects
    }
  end

  defp get_title(endpoint) do
    special = Storage.EndpointModel.special_field(endpoint)
    Storage.ServiceIds.translate(special)
  end

  defp get_tab_keys(endpoint) do
    special = Storage.EndpointModel.special_field(endpoint)

    []
    |> append_if(:settings, special != :builtin)
    |> append_if(:data, special == :builtin)
    |> append(:monitor)
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
    ready? = false

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
         %{fabric: fabric, timezone: timezone} = _assigns
       ) do
    ready? = false

    files =
      endpoint
      |> Storage.Public.list_files()
      |> Enum.map(fn %{timestamp: timestamp} = file ->
        %{file | timestamp: Timestamp.convert(timestamp, timezone)}
      end)

    child =
      Fabric.prepare_child(fabric, :data_view, Storage.EndpointDataView, %{
        endpoint: endpoint,
        files: files,
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
         :monitor,
         endpoint,
         show_errors,
         %{fabric: fabric} = _assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :monitor_view, Storage.EndpointMonitorView, %{
        endpoint: endpoint
      })

    %{
      id: :monitor_view,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-storage", "tabbar.item.monitor"),
      forward_title: dgettext("eyra-storage", "tabbar.item.monitor.forward"),
      type: :fullpage,
      child: child
    }
  end
end
