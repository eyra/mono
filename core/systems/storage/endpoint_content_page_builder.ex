defmodule Systems.Storage.EndpointContentPageBuilder do
  import CoreWeb.Gettext
  import Frameworks.Utility.List

  alias Frameworks.Concept.Context
  alias CoreWeb.UI.Timestamp
  alias Systems.Storage
  alias Systems.Monitor

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
    context_name = Context.name(endpoint, "Current")

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
        context_name: context_name,
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
        number_widgets: number_widgets(endpoint)
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

  defp number_widgets(endpoint) do
    [:write_count, :write_volume]
    |> Enum.map(&number_widget(&1, endpoint))
  end

  defp number_widget(:write_volume, special) do
    sum =
      Monitor.Public.event({special, :write})
      |> Monitor.Public.sum()

    {label, metric} =
      if sum >= 1024 * 1024 do
        {
          dgettext("eyra-storage", "write_volume.mb.metric.label"),
          Integer.floor_div(sum, 1024 * 1024)
        }
      else
        {
          dgettext("eyra-storage", "write_volume.kb.metric.label"),
          Integer.floor_div(sum, 1024)
        }
      end

    %{
      label: label,
      metric: metric,
      color: :primary
    }
  end

  defp number_widget(:write_count, endpoint) do
    metric =
      Monitor.Public.event({endpoint, :write})
      |> Monitor.Public.count()

    %{
      label: dgettext("eyra-storage", "write_count.metric.label"),
      metric: metric,
      color: :primary
    }
  end
end
