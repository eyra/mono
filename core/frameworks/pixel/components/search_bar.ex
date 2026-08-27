defmodule Frameworks.Pixel.SearchBar do
  @moduledoc false
  use CoreWeb, :live_component
  use Frameworks.Pixel.FabricBridge

  @impl true
  def update(%{id: id, query_string: query_string, placeholder: placeholder, debounce: debounce} = assigns, socket) do
    {
      :ok,
      assign(socket,
        id: id,
        query_string: query_string,
        placeholder: placeholder,
        debounce: debounce,
        target: Map.get(assigns, :target)
      )
    }
  end

  @impl true
  def handle_event("change", %{"query" => query}, socket) do
    {
      :noreply,
      send_to_parent(socket, query)
    }
  end

  @impl true
  def handle_event("submit", %{"query" => query}, socket) do
    {
      :noreply,
      send_to_parent(socket, query)
    }
  end

  defp send_to_parent(socket, "") do
    send_to_parent(socket, %{
      query_string: "",
      query: nil
    })
  end

  defp send_to_parent(socket, query) when is_binary(query) do
    send_to_parent(socket, %{
      query_string: query,
      query: String.split(query, " ")
    })
  end

  defp send_to_parent(%{assigns: %{target: {module, id}}} = socket, %{} = message) do
    send_update(module, id: id, search_query: message)
    socket
  end

  defp send_to_parent(socket, %{} = message) do
    emit_to_parent(socket, {"search_query", message})
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
