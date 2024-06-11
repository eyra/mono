defmodule Systems.Org.ContentPageBuilder do
  import CoreWeb.Gettext

  alias Systems.Org

  def view_model(node, assigns) do
    %{
      title: dgettext("eyra-org", "org.content.title"),
      tabs: create_tabs(node, assigns),
      actions: [],
      more_actions: [],
      show_errors: false,
      active_menu_item: :admin
    }
  end

  defp create_tabs(node, assigns) do
    [:node, :users]
    |> Enum.map(&create_tab(&1, node, assigns))
  end

  defp create_tab(:node, node, %{fabric: fabric, locale: locale}) do
    child =
      Fabric.prepare_child(fabric, :node, Org.NodeContentView, %{
        locale: locale,
        node: node
      })

    %{
      id: :node,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-org", "node.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:users, _node, %{fabric: fabric, locale: locale}) do
    child =
      Fabric.prepare_child(fabric, :users, Org.UserView, %{
        locale: locale
      })

    %{
      id: :users,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-org", "user.title"),
      type: :fullpage,
      child: child
    }
  end
end
