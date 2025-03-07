defmodule Systems.Project.NodePageBuilder do
  use Core.FeatureFlags

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Storage.EndpointDataView

  alias Systems.Project.NodePageEmptyDataView
  alias Systems.Project.NodePageGridView
  alias Frameworks.Concept
  alias Systems.Project

  def view_model(
        %Project.NodeModel{id: id} = node,
        %{
          fabric: _fabric
        } = assigns
      ) do
    assigns = Map.put(assigns, :node, node)

    %{
      id: id,
      title: node.name,
      show_errors: false
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
         %{fabric: fabric, timezone: timezone, node: node} = _assigns
       ) do
    case Enum.find(node.items, &(&1.name == "Data" and &1.storage_endpoint)) do
      %{storage_endpoint: storage_endpoint} ->
        ready? = true
        branch = %Project.Branch{node_id: node.id}
        branch_name = Concept.Branch.name(branch, :parent)

        child =
          Fabric.prepare_child(fabric, :data, EndpointDataView, %{
            endpoint: storage_endpoint,
            branch_name: branch_name,
            timezone: timezone
          })

        %{
          id: :data,
          ready: ready?,
          show_errors: show_errors,
          title: dgettext("eyra-storage", "tabbar.item.data"),
          forward_title: dgettext("eyra-storage", "tabbar.item.data.forward"),
          type: :fullpage,
          child: child
        }

      nil ->
        child =
          Fabric.prepare_child(fabric, :data, NodePageEmptyDataView, %{
            node: node
          })

        %{
          id: :data,
          ready: false,
          show_errors: show_errors,
          title: dgettext("eyra-storage", "tabbar.item.data"),
          type: :fullpage,
          child: child
        }
    end
  end

  defp get_tab_keys() do
    [
      :overview,
      :data
    ]
  end
end
