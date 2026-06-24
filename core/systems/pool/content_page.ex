defmodule Systems.Pool.ContentPage do
  @moduledoc """
  Pool-scoped admin page (a "Pool Admin" view). Mirrors `Systems.Org.ContentPage`'s
  tabbar structure but scoped to a single pool. Reached from the Org page's
  Pools tab. Tabs (Participants, …) land in follow-up commits — this commit
  ships the scaffold + auth + breadcrumb.
  """
  use Systems.Content.Composer, {:tabbar_page, :live_nest}

  alias Systems.Pool

  @impl true
  def get_authorization_context(params, session, socket) do
    pool = get_model(params, session, socket)
    user = Map.get(socket.assigns, :current_user)

    if Pool.Public.can_manage?(pool, user), do: pool, else: nil
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Pool.Public.get!(id, Pool.Model.preload_graph(:org))
  end

  @impl true
  def mount(%{"id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "pool_content/#{id}"

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
