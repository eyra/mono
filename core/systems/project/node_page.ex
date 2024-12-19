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
  def handle_event("delete", %{"item" => item_id}, socket) do
    Project.Public.delete_item(String.to_integer(item_id))

    {
      :noreply,
      socket
      |> update_view_model()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_item", _params, socket) do
    {
      :noreply,
      socket
      |> compose_child(:create_item_view)
      |> show_modal(:create_item_view, :dialog)
    }
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{vm: %{item_cards: item_cards, node_cards: node_cards}}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(item_cards ++ node_cards, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def handle_event("saved", %{source: %{name: modal_view}}, socket) do
    {:noreply, socket |> hide_modal(modal_view)}
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
