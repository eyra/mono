defmodule Systems.Zircon.Screening.ImportSessionErrorsView do
  use CoreWeb, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.Paginator, only: [paginator: 1]
  import Systems.Zircon.HTML, only: [ris_entry_error_table: 1]

  alias Frameworks.Pixel.Text

  @page_size 10

  def get_model(:not_mounted_at_router, %{"session" => session}, _socket) do
    # Add an id to the model so it works with the default observe_view_model
    Map.put(session, :id, "import_session_errors")
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
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

  defp update_pagination(%{assigns: %{vm: vm, page_index: page_index, query: query}} = socket) do
    filtered_errors = filter_errors(vm.errors, query)
    error_count = length(filtered_errors)
    page_count = max(1, ceil(error_count / @page_size))
    page_errors = filtered_errors |> Enum.slice(page_index * @page_size, @page_size)

    socket
    |> update(:vm, fn vm ->
      vm
      |> Map.put(:filtered_errors, filtered_errors)
      |> Map.put(:page_errors, page_errors)
      |> Map.put(:error_count, error_count)
      |> Map.put(:page_count, page_count)
      |> Map.put(:page_index, page_index)
      |> Map.put(:query, query)
    end)
  end

  defp filter_errors(errors, nil), do: errors
  defp filter_errors(errors, []), do: errors

  defp filter_errors(errors, query) when is_list(query) do
    Enum.filter(errors, fn error ->
      # Search in all fields: line number, error message, and content
      searchable_text =
        [
          "Line #{error.line}",
          error.error || "",
          error.content || ""
        ]
        |> Enum.join(" ")
        |> String.downcase()

      Enum.any?(query, fn phrase ->
        phrase |> String.downcase() |> then(&String.contains?(searchable_text, &1))
      end)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="errors-block">
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
