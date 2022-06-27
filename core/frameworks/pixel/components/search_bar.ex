defmodule Frameworks.Pixel.SearchBar do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias Surface.Components.Form

  prop(query_string, :any, default: nil)
  prop(placeholder, :string, default: "")
  prop(parent, :any, required: true)
  prop(debounce, :string, default: "1000")

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

  def render(assigns) do
    ~F"""
    <Form for={:x} submit="submit" change="change" opts={id: "#{@id}_form"}>
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
    </Form>
    """
  end
end

defmodule Frameworks.Pixel.SearchBar.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.SearchBar,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Search Bar",
    height: "640px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <Frameworks.Pixel.SearchBar
      id={:my_search_bar}
      query_string=""
      placeholder="Search here.."
      parent={self()}
    />
    """
  end

  def handle_info(%{search_bar: :my_search_bar, query: _query}, socket) do
    {
      :noreply,
      socket
    }
  end
end
