defmodule Frameworks.Pixel.List do
  @moduledoc """
  A generic list LiveComponent with optional search + pagination.

  Consumers pass in the full `rows` list and a `:row` slot that renders
  one row. Adding a `haystack_fn` enables search; adding `page_size`
  enables pagination.

  Row-level actions (e.g. `phx-target={@myself}`) resolve to the CONSUMER
  LC because slot content is compiled in the consumer's rendering
  context — so an "action" button in a row fires against the consumer,
  not this wrapper.
  """
  use CoreWeb, :live_component

  import Frameworks.Pixel.Paginator, only: [paginator: 1]

  alias Frameworks.Pixel.SearchBar

  @impl true
  def update(%{id: _id, search_query: %{query: query, query_string: query_string}}, socket) do
    {:ok,
     socket
     |> assign(query: query, query_string: query_string, page_index: 0)
     |> recompute()}
  end

  @impl true
  def update(%{id: id, rows: rows} = assigns, socket) do
    {:ok,
     socket
     |> assign(
       id: id,
       rows: rows,
       page_size: Map.get(assigns, :page_size),
       haystack_fn: Map.get(assigns, :haystack_fn),
       placeholder: Map.get(assigns, :placeholder, "Search"),
       no_match_message: Map.get(assigns, :no_match, ""),
       justify: Map.get(assigns, :justify, :start),
       item_height: Map.get(assigns, :item_height, "54px"),
       stretch: Map.get(assigns, :stretch, false),
       row: Map.get(assigns, :row),
       empty: Map.get(assigns, :empty)
     )
     |> assign_new(:query, fn -> nil end)
     |> assign_new(:query_string, fn -> "" end)
     |> assign_new(:page_index, fn -> 0 end)
     |> recompute()}
  end

  @impl true
  def handle_event("select_page", %{"item" => index}, socket) do
    {:noreply, socket |> assign(page_index: String.to_integer(index)) |> recompute()}
  end

  defp recompute(%{assigns: assigns} = socket) do
    filtered = filter_rows(assigns.rows, assigns.query, assigns.haystack_fn)
    filtered_count = length(filtered)
    page_size = assigns.page_size
    page_count = page_count(filtered_count, page_size)
    page_index = clamp_page(assigns.page_index, page_count)
    visible = slice(filtered, page_index, page_size)

    assign(socket,
      visible_rows: visible,
      filtered_count: filtered_count,
      page_index: page_index,
      page_count: page_count
    )
  end

  defp filter_rows(rows, nil, _fn), do: rows
  defp filter_rows(rows, _terms, nil), do: rows
  defp filter_rows(rows, [], _fn), do: rows

  defp filter_rows(rows, terms, haystack_fn)
       when is_list(terms) and is_function(haystack_fn, 1) do
    Enum.filter(rows, fn row ->
      haystack = row |> haystack_fn.() |> String.downcase()
      Enum.all?(terms, &String.contains?(haystack, String.downcase(&1)))
    end)
  end

  # No pagination configured → single "page" of all rows.
  defp page_count(_count, nil), do: 1
  defp page_count(0, _size), do: 0
  defp page_count(count, size), do: div(count - 1, size) + 1

  defp clamp_page(_index, 0), do: 0
  defp clamp_page(index, page_count) when index >= page_count, do: page_count - 1
  defp clamp_page(index, _) when index < 0, do: 0
  defp clamp_page(index, _), do: index

  defp slice(rows, _page_index, nil), do: rows
  defp slice(rows, page_index, size), do: Enum.slice(rows, page_index * size, size)

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:page_size, :integer, default: nil)
  attr(:haystack_fn, :any, default: nil)
  attr(:placeholder, :string, default: "Search")
  attr(:no_match, :string, default: "")
  attr(:justify, :atom, default: :start)
  # Height of a single row. The wrapper reserves `page_size × item_height`
  # on the row area when paginated so the search bar (above) and paginator
  # (below) stay anchored on short pages. Default matches a
  # `py-3 text-bodymedium` row.
  attr(:item_height, :string, default: "54px")
  attr(:stretch, :boolean, default: false)
  slot(:row, required: true)
  slot(:empty)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if search_bar_visible?(assigns) do %>
        <div class="mb-4">
          <.live_component
            module={SearchBar}
            id={"#{@id}-search"}
            query_string={@query_string}
            placeholder={@placeholder}
            debounce="300"
            target={{__MODULE__, @id}}
          />
        </div>
      <% end %>

      <%= cond do %>
        <% Enum.empty?(@rows) -> %>
          <%= render_slot(@empty) %>
        <% @filtered_count == 0 -> %>
          <div class="text-bodymedium font-body text-grey2 pb-6">
            <%= @no_match_message %>
          </div>
        <% true -> %>
          <div class="mb-6" style={min_height_style(@item_height, @page_size, @page_count)}>
            <table class={if @stretch, do: "w-full", else: "w-auto"}>
              <tbody>
                <%= for row <- @visible_rows do %>
                  <%= render_slot(@row, row) %>
                <% end %>
              </tbody>
            </table>
          </div>

          <%= if @page_count > 1 do %>
            <div class="mb-6">
              <.paginator
                active_page={@page_index}
                page_count={@page_count}
                target={@myself}
                justify={@justify}
              />
            </div>
          <% end %>
      <% end %>
    </div>
    """
  end

  # SearchBar is only useful with a haystack. Show it only when there's
  # something to search (a full page's worth) or a query is already active.
  defp search_bar_visible?(%{haystack_fn: nil}), do: false
  defp search_bar_visible?(%{query_string: q}) when q not in [nil, ""], do: true

  defp search_bar_visible?(%{rows: rows, page_size: page_size}) when is_integer(page_size),
    do: length(rows) > page_size

  defp search_bar_visible?(_), do: false

  # Only reserve space when pagination is actually rendered — a short list
  # that fits in one page should hug its content.
  defp min_height_style(_item_height, _page_size, page_count) when page_count < 2, do: nil
  defp min_height_style(_item_height, nil, _page_count), do: nil

  defp min_height_style(item_height, page_size, _page_count) do
    "min-height: calc(#{page_size} * #{item_height})"
  end
end
