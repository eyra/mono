defmodule Systems.Zircon.Screening.ImportSessionErrorsView do
  use CoreWeb, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.Paginator, only: [paginator: 1]
  import Systems.Zircon.HTML, only: [ris_entry_error_table: 1]

  alias Frameworks.Pixel.Text

  def get_model(:not_mounted_at_router, %{"session" => session} = _session, _socket) do
    session
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def mount(:not_mounted_at_router, %{"title" => title} = _session, socket) do
    {:ok, assign(socket, title: title)}
  end

  @impl true
  def handle_event("select_page", %{"item" => page}, socket) do
    page_index = String.to_integer(page)

    {:noreply,
     socket
     |> assign(page_index: page_index, query: socket.assigns.vm.query)
     |> update_pagination()}
  end

  @impl true
  def consume_event(
        %{name: "search_query", payload: %{query: query, query_string: _query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(page_index: 0, query: query)
      |> update_pagination()
    }
  end

  defp update_pagination(socket) do
    # Trigger ViewBuilder to recalculate with new pagination parameters
    update_view_model(socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="errors-block">
      <Text.title2><%= @title %> <span class="text-warning"><%= @vm.error_count %></span></Text.title2>

      <%= if @vm.show_action_bar? do %>
        <.action_bar
          page_index={@vm.page_index}
          page_count={@vm.page_count}
          search_bar={@vm.search_bar}
          socket={@socket}
        />
        <.spacing value="S" />
      <% end %>

      <div data-testid="errors-list">
        <.ris_entry_error_table errors={@vm.page_errors} />
      </div>
    </div>
    """
  end

  defp action_bar(assigns) do
    ~H"""
    <div class="flex flex-row items-center">
      <.paginator active_page={@page_index} page_count={@page_count} />
      <div class="flex-grow" />
      <Text.caption>
        <%= @page_count %> pages
      </Text.caption>
      <LiveNest.HTML.element {Map.from_struct(@search_bar)} socket={@socket} />
    </div>
    """
  end
end
