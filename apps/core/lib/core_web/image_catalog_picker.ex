defmodule CoreWeb.ImageCatalogPicker do
  use Surface.LiveComponent

  prop(image_catalog, :any, required: true)
  data(query, :string, default: "")
  data(search_results, :list, default: [])

  def render(assigns) do
    ~H"""
    <div>
        <h2>Catalog browser</h2>
        <form :on-submit="search">
        <input type="search" name="q"/>
        <button type="submit">Search</button>
        </form>
        <div :if={{@search_results == [] && @query != ""}}>
          No results
        </div>
        <div :if={{@search_results != []}}>
          <div :for={{ image <- @search_results }} class="image" :on-click="select_image" phx-value-image={{image.id}}>
            <img src={{image.url}} srcset={{image.srcset}}/>
          </div>
        </div>
    </div>
    """
  end

  def handle_event(
        "search",
        %{"q" => query},
        %{assigns: %{image_catalog: image_catalog}} = socket
      ) do
    results = image_catalog.search_info(query, with: 200, height: 200)
    {:noreply, socket |> assign(query: query, search_results: results)}
  end

  def handle_event("select_image", %{"image" => image_id}, %{assigns: %{id: id}} = socket) do
    send(self(), {id, image_id})
    {:noreply, socket}
  end
end
