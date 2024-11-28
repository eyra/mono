defmodule Systems.Project.NodePageBuilder do
  use Core.FeatureFlags

  import CoreWeb.Gettext

  alias Systems.Project.NodePageGridView
  alias Frameworks.Concept
  alias Systems.Project

  def view_model(
        %Project.NodeModel{id: id} = node,
        %{
          fabric: fabric
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
        Project.NodePageGridViewBuilder.view_model(node, assigns)
      )

    %{
      id: :overview,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-projects", "projects.title"),
      type: :fullpage,
      child: child
    }
  end

  defp get_tab_keys() do
    [:overview]
  end
end
