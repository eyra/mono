defmodule Frameworks.Pixel.SearchBar do
  @moduledoc false
  use CoreWeb, :live_component
  @impl true
  def update(
        %{
          id: id,
          query_string: query_string,
          placeholder: placeholder,
          parent: parent,
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
        parent: parent,
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

  defp send_to_parent(%{assigns: %{id: id, parent: parent}} = socket, "") do
    update_target(parent, %{search_bar: id, query_string: "", query: nil})
    socket
  end

  defp send_to_parent(%{assigns: %{id: id, parent: parent}} = socket, query_string) do
    update_target(parent, %{
      search_bar: id,
      query_string: query_string,
      query: String.split(query_string, " ")
    })

    socket
  end

  attr(:query_string, :any, default: nil)
  attr(:placeholder, :string, default: "")
  attr(:parent, :any, required: true)
  attr(:debounce, :string, default: "1000")
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_form"} for={%{}} phx-submit="submit" phx-change="change" phx-target={@parent}>
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
