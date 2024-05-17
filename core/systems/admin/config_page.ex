defmodule Systems.Admin.ConfigPage do
  use Systems.Content.Composer, :tabbar_page

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(title: dgettext("eyra-admin", "config.title"))
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <.tabbar_page
      title={@vm.title}
      menus={@menus}
      popup={@popup}
      dialog={@dialog}
      tabs={@vm.tabs}
      tabbar_id={@tabbar_id}
      initial_tab={@initial_tab}
      show_errors={@vm.show_errors}
    />
    """
  end
end
