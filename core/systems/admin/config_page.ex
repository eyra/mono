defmodule Systems.Admin.ConfigPage do
  use Systems.Content.Composer, {:tabbar_page, :live_nest}

  alias Systems.Admin
  alias Systems.Org

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(params, _session, %{assigns: %{current_user: user}} = socket) do
    # Non-admin users with a single org should go directly to the org content page
    if not Admin.Public.admin?(user) do
      case Org.Public.list_orgs(user) do
        [%{id: org_id}] ->
          {:ok, push_navigate(socket, to: ~p"/org/node/#{org_id}")}

        _ ->
          mount_with_tabs(params, socket)
      end
    else
      mount_with_tabs(params, socket)
    end
  end

  defp mount_with_tabs(params, socket) do
    initial_tab = Map.get(params, "tab")
    {:ok, socket |> assign(initial_tab: initial_tab)}
  end

  @impl true
  def handle_event("change", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", %{"item" => modal_id}, socket) do
    {:noreply, socket |> handle_close_modal(modal_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.tabbar_page
      socket={@socket}
      title={@vm.title}
      tabs={@vm.tabs}
      tabbar_id={@vm.tabbar_id}
      show_errors={@vm.show_errors}
      initial_tab={@initial_tab}
      menus={@menus}
      modal={@modal}
    />
    """
  end
end
