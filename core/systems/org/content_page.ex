defmodule Systems.Org.ContentPage do
  use Systems.Content.Composer, {:tabbar_page, :live_nest}

  alias Systems.Org

  @impl true
  def get_authorization_context(params, session, socket) do
    org = get_model(params, session, socket)
    user = Map.get(socket.assigns, :current_user)

    if Org.Public.can_manage?(org, user), do: org, else: nil
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Org.Public.get_node!(id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(%{"id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "org_content/#{id}"

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        initial_tab: initial_tab
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.tabbar_page_breadcrumbs
        socket={@socket}
        title={@vm.title}
        tabs={@vm.tabs}
        breadcrumbs={@vm.breadcrumbs}
        show_errors={@vm.show_errors}
        tabbar_id={@tabbar_id}
        initial_tab={@initial_tab}
        menus={@menus}
        modal={@modal}
      />
    """
  end
end
