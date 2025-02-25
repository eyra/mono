defmodule Systems.Project.NodePage do
  use Systems.Content.Composer, :live_workspace

  alias Systems.Project

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Project.Public.get_node!(String.to_integer(id), Project.NodeModel.preload_graph(:down))
  end

  @impl true
  def mount(params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    {:ok, socket |> assign(initial_tab: initial_tab)}
  end

  def handle_event(:should_flash_message, %{status: status, message: message}, socket) do
    {
      :noreply,
      socket
      |> put_flash(status, message)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.tabbar_page
        title={@vm.title}
        tabs={@vm.tabs}
        tabbar_id={@vm.tabbar_id}
        show_errors={@vm.show_errors}
        initial_tab={@initial_tab}
        menus={@menus}
        modals={@modals}
        popup={@popup}
        dialog={@dialog}
      />
    """
  end
end
