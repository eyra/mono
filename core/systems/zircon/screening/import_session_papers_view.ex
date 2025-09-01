defmodule Systems.Zircon.Screening.ImportSessionPapersView do
  use CoreWeb, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Zircon.HTML, only: [ris_entry_table: 1]
  import Frameworks.Pixel.Paginator, only: [paginator: 1]

  alias Frameworks.Pixel.Text

  def get_model(
        :not_mounted_at_router,
        %{"session" => %{id: id} = session, "filter" => filter},
        _socket
      ) do
    %{
      id: id,
      session: session,
      filter: filter
    }
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def mount(:not_mounted_at_router, session, socket) when is_map(session) do
    # Extract title and filter, handling both string and atom keys
    title = Map.get(session, "title")
    filter = Map.get(session, "filter")
    {:ok, socket |> assign(title: title, page_index: 0, query: nil, filter: filter)}
  end

  @impl true
  def handle_event("select_page", %{"item" => page}, socket) do
    page_index = String.to_integer(page)
    {:noreply, socket |> assign(page_index: page_index) |> update_pagination()}
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
    <div data-testid="papers-block">
      <Text.title2><%= @title %> <span class="text-primary"><%= @vm.paper_count %></span></Text.title2>

      <%= if @vm.show_action_bar? do %>
        <.action_bar
          page_index={@vm.page_index}
          page_count={@vm.page_count}
          search_bar={@vm.search_bar}
          socket={@socket}
        />
        <.spacing value="S" />
      <% end %>

      <%= if @vm.paper_count > 0 do %>
        <div data-testid="papers-table">
          <.ris_entry_table items={@vm.page_papers} />
        </div>
      <% else %>
        <div data-testid="papers-description">
          <Text.body><%= @vm.description %></Text.body>
        </div>
      <% end %>
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
