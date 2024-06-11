defmodule Frameworks.Pixel.SearchBar do
  @moduledoc false
  use CoreWeb, :live_component

  @impl true
  def update(
        %{
          id: id,
          query_string: query_string,
          placeholder: placeholder,
          debounce: debounce
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        query_string: query_string,
        placeholder: placeholder,
        debounce: debounce
      )
    }
  end

  @impl true
  def handle_event(
        "change",
        %{"query" => query},
        socket
      ) do
    {
      :noreply,
      socket
      |> send_to_parent(query)
    }
  end

  @impl true
  def handle_event(
        "submit",
        %{"query" => query},
        socket
      ) do
    {
      :noreply,
      socket
      |> send_to_parent(query)
    }
  end

  defp send_to_parent(socket, "") do
    socket
    |> send_event(:parent, "search_query", %{
      query_string: "",
      query: nil
    })
  end

  defp send_to_parent(socket, query_string) do
    socket
    |> send_event(:parent, "search_query", %{
      query_string: query_string,
      query: String.split(query_string, " ")
    })
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_form"} for={%{}} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="flex flex-row">
          <input
            class="text-grey1 text-bodymedium font-body pl-3 pr-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-48px"
            placeholder={@placeholder}
            value={@query_string}
            name="query"
            type="search"
            phx-debounce={@debounce}
          />
        </div>
      </.form>
    </div>
    """
  end
end
