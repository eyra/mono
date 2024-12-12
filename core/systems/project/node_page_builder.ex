defmodule Systems.Project.NodePageBuilder do
  use Core.FeatureFlags

  import CoreWeb.Gettext

  alias Systems.Storage.EndpointFilesView
  alias Systems.Storage.EndpointDataView
  alias Systems.Project.NodePageGridView
  alias Frameworks.Concept
  alias Systems.Project

  def view_model(
        %Project.NodeModel{id: id} = node,
        %{
          fabric: _fabric
        } = assigns
      ) do
    branch = %Project.Branch{node_id: node.id}
    breadcrumbs = Concept.Branch.hierarchy(branch)
    assigns = Map.put(assigns, :node, node)

    %{
      id: id,
      title: node.name,
      tabbar_id: :node_page,
      show_errors: false,
      initial_tab: :overview,
      active_menu_item: :overview,
      breadcrumbs: breadcrumbs,
      node: node
    }
    |> put_tabs(assigns)
  end

  defp put_tabs(vm, assigns) do
    Map.put(vm, :tabs, create_tabs(false, assigns))
  end

  defp create_tabs(show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, show_errors, assigns))
  end

  defp create_tab(
         :overview,
         show_errors,
         %{fabric: fabric, node: node} = assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(
        fabric,
        :overview,
        NodePageGridView,
        %{
          node: node,
          user: assigns.current_user,
          timezone: assigns.timezone
        }
      )

    %{
      id: :overview,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-projects", "items.overview"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :data,
         show_errors,
         %{
           branch: branch,
           fabric: fabric,
           timezone: timezone,
           node: %{items: [%{name: "Data", storage_endpoint: storage_endpoint} | _rest]}
         } = _assigns
       ) do
    ready? = true
    # branch_name = Concept.Branch.name(branch, :parent)
    # TODO
    branch_name = "master"

    child =
      Fabric.prepare_child(fabric, :data_view, EndpointDataView, %{
        endpoint: storage_endpoint,
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
         :data,
         show_errors,
         %{
           branch: branch,
           fabric: fabric,
           timezone: timezone
         } = assigns
       ) do
    ready? = true

    branch_name = "master"

    child =
      Fabric.prepare_child(fabric, :data_view, EndpointFilesView, %{
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

  defp get_tab_keys() do
    [
      :overview,
      :data
    ]
  end
end
