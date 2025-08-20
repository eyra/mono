defmodule Systems.Zircon.Screening.ImportSessionNewPapersView do
  use CoreWeb, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Zircon.HTML, only: [ris_entry_table: 1]
  import Frameworks.Pixel.Paginator, only: [paginator: 1]

  alias Frameworks.Pixel.Text

  @page_size 10

  def get_model(:not_mounted_at_router, %{"session" => session}, _socket) do
    # Add an id to the model so it works with the default observe_view_model
    Map.put(session, :id, "import_session_new_papers")
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(page_index: 0, query: nil)}
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
    # Get assigns with defaults
    page_index = Map.get(socket.assigns, :page_index, 0)
    query = Map.get(socket.assigns, :query, nil)
    vm = socket.assigns.vm

    filtered_papers = filter_papers(vm.new_papers, query)
    paper_count = length(filtered_papers)
    page_count = max(1, ceil(paper_count / @page_size))
    page_papers = filtered_papers |> Enum.slice(page_index * @page_size, @page_size)

    socket
    |> update(:vm, fn vm ->
      vm
      |> Map.put(:filtered_papers, filtered_papers)
      |> Map.put(:page_papers, page_papers)
      |> Map.put(:paper_count, paper_count)
      |> Map.put(:page_count, page_count)
      |> Map.put(:page_index, page_index)
      |> Map.put(:query, query)
    end)
  end

  defp filter_papers(papers, nil), do: papers
  defp filter_papers(papers, []), do: papers

  defp filter_papers(papers, query) when is_list(query) do
    Enum.filter(papers, &filter_paper(&1, query))
  end

  defp filter_paper(paper, query) when is_list(query) do
    Enum.any?(query, fn phrase -> match_paper?(paper, phrase) end)
  end

  defp match_paper?(%{title: title, authors: authors} = paper, phrase) when is_binary(phrase) do
    searchable_fields =
      [
        title,
        Map.get(paper, :doi, ""),
        to_string(Map.get(paper, :year, ""))
      ] ++ (authors || [])

    searchable_fields
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.any?(fn field ->
      field |> String.contains?(String.downcase(phrase))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="new-papers-block">
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
        <div data-testid="new-papers-table">
          <.ris_entry_table items={@vm.page_papers} />
        </div>
      <% else %>
        <div data-testid="new-papers-description">
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
