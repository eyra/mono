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
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
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
        initial_tab={@vm.initial_tab}
        menus={@menus}
        modal={@modal}
        popup={@popup}
        dialog={@dialog}
      />
    """
  end
end
