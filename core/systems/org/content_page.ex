defmodule Systems.Org.ContentPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :admin
  use CoreWeb.UI.Responsive.Viewport

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  alias Systems.{
    Org
  }

  @impl true
  def mount(%{"id" => id}, %{"locale" => locale}, socket) do
    node = Org.Public.get_node!(id, Org.NodeModel.preload_graph(:full))
    tabbar_id = "org_content/#{id}"

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        node: node,
        locale: locale
      )
      |> assign_breakpoint()
      |> create_tabs()
      |> update_tabbar()
      |> update_menus()
    }
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_tabbar()
    |> update_menus()
  end

  @impl true
  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  defp update_tabbar(%{assigns: %{breakpoint: breakpoint}} = socket) do
    tabbar_size = tabbar_size(breakpoint)

    socket
    |> assign(tabbar_size: tabbar_size)
  end

  defp create_tabs(%{assigns: %{node: node, locale: locale}} = socket) do
    tabs = [
      %{
        id: :node,
        ready: true,
        title: dgettext("eyra-org", "node.title"),
        type: :fullpage,
        live_component: Systems.Org.NodeContentView,
        props: %{
          locale: locale,
          node: node
        }
      },
      %{
        id: :users,
        ready: true,
        title: dgettext("eyra-org", "user.title"),
        type: :fullpage,
        live_component: Systems.Org.UserView,
        props: %{
          locale: locale
        }
      }
    ]

    socket
    |> assign(tabs: tabs)
  end

  defp tabbar_size({:unknown, _}), do: :unknown
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{30 => :wide})

  # data(tabbar_id, :string)
  # data(node, :map)
  # data(tabs, :list)
  # data(bar_size, :number)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-org", "org.content.title")} menus={@menus}>
      <Navigation.action_bar>
        <Tabbar.container id={@tabbar_id} tabs={@tabs} size={@tabbar_size} />
      </Navigation.action_bar>
      <Tabbar.content tabs={@tabs} />
    </.workspace>
    """
  end
end
