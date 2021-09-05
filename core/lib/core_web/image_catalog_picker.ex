defmodule CoreWeb.ImageCatalogPicker do
  use CoreWeb.UI.LiveComponent

  alias EyraUI.Text.{Title3, BodyLarge, Caption}
  alias EyraUI.Button.SubmitButton
  alias EyraUI.Grid.ImageGrid

  prop(conn, :any, required: true)
  prop(viewport, :any)
  prop(breakpoint, :any)
  prop(static_path, :any, required: true)
  prop(image_catalog, :any, required: true)
  prop(initial_query, :string, default: "")
  prop(target, :any, default: "")

  data(query, :string, default: nil)
  data(search_results, :list, default: nil)
  data(meta, :any, default: nil)

  defp gap(%{"width" => width}, :mobile) when width < 400, do: "gap-4"
  defp gap(%{"width" => width}, :mobile) when width < 500, do: "gap-8"
  defp gap(_, _), do: "gap-10"

  defp page_size(_, :mobile), do: 6
  defp page_size(_, :sm), do: 6
  defp page_size(_, :md), do: 9
  defp page_size(_, :lg), do: 8
  defp page_size(_, _), do: 10

  defp page_count(%{"width" => width}, :mobile), do: Integer.floor_div(width, 100) + 1
  defp page_count(_, :sm), do: 8
  defp page_count(_, :md), do: 10
  defp page_count(_, :lg), do: 10
  defp page_count(_, _), do: 10

  def update(
        %{viewport: new_viewport, breakpoint: new_breakpoint},
        %{assigns: %{viewport: current_viewport}} = socket
      ) do
    socket =
      if new_viewport != current_viewport do
        socket
        |> assign(viewport: new_viewport)
        |> assign(breakpoint: new_breakpoint)
        |> assign(search_results: nil)
        |> assign(query: nil)
        |> assign(meta: nil)
      else
        socket
      end

    {
      :ok,
      socket
    }
  end

  def update(
        %{
          id: id,
          conn: conn,
          viewport: viewport,
          breakpoint: breakpoint,
          static_path: static_path,
          image_catalog: image_catalog,
          initial_query: initial_query,
          target: target
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(conn: conn)
      |> assign(viewport: viewport)
      |> assign(breakpoint: breakpoint)
      |> assign(static_path: static_path)
      |> assign(image_catalog: image_catalog)
      |> assign(initial_query: initial_query)
      |> assign(target: target)
    }
  end

  def handle_event(
        "search",
        %{"q" => query},
        %{assigns: %{image_catalog: image_catalog}} = socket
      ) do
    search(socket, query, image_catalog, 1)
  end

  def handle_event(
        "select_page",
        %{"page" => page},
        %{assigns: %{query: query, image_catalog: image_catalog}} = socket
      ) do
    search(socket, query, image_catalog, String.to_integer(page))
  end

  def handle_event("select_image", %{"image" => image_id}, %{assigns: %{id: id}} = socket) do
    send(self(), {id, image_id})
    {:noreply, socket}
  end

  defp search(
         %{assigns: %{viewport: viewport, breakpoint: breakpoint}} = socket,
         query,
         image_catalog,
         page
       ) do
    page_size = page_size(viewport, breakpoint)
    results = image_catalog.search_info(query, page, page_size, width: 400, height: 300)

    {:noreply,
     socket
     |> assign(
       query: query,
       initial_query: query,
       search_results: results.images,
       meta: results.meta
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded">
      <div class="pl-6 pr-6 pt-6 pb-8 lg:pt-8 lg:pb-10 lg:pr-8 lg:pl-8">
        <div class="flex flex-row">
          <div class="flex-grow">
            <Title3>{{dgettext("eyra-imagecatalog", "search.image.title")}}</Title3>
          </div>
          <button type="button" class="w-button-sm h-button-sm flex-wrap cursor-pointer active:opacity-50" x-on:click="image_picker = false, $parent.$parent.overlay = false">
            <img src={{ @static_path.(@conn, "/images/close.svg")}} />
          </button>
        </div>
        <div x-data="{ selected: -1 }">
          <form id="image_catalog_picker_form" :on-submit="search">
            <div class="flex flex-row">
              <input value={{@initial_query}} class="text-grey1 text-bodymedium font-body pl-3 pr-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-48px" name="q" type="search" />
              <Spacing value="XS" direction="l" />
              <SubmitButton label="{{dgettext("eyra-imagecatalog", "search.image.button")}}" alpine_onclick="selected = -1" />
            </div>
          </form>
          <div :if={{@search_results == [] && @query != ""}}>
            <Spacing value="S" />
            <BodyLarge>{{dgettext("eyra-imagecatalog", "no.results.found.message")}}</BodyLarge>
          </div>
          <div :if={{@search_results && @search_results != []}}>
            <Spacing value="S" />
            <BodyLarge>{{dngettext("eyra-imagecatalog", "images.found.message", "images.found.message.%{count}",  @meta.image_count )}}</BodyLarge>
            <Spacing value="S" />
            <ImageGrid gap={{ gap(@viewport, @breakpoint) }}>
              <div :for={{ {image, index} <- Enum.with_index(@search_results) }}>
                <ImageGrid.Image vm={{ Map.merge(image, %{index: index, target: @myself }) }} />
              </div>
            </ImageGrid>
            <Spacing value="S" />
            <div class="flex flex-row">
              <div class="flex-grow">
                <Caption text_alignment="left" padding="p-0" margin="m-0" color="text-grey2">{{dngettext("eyra-imagecatalog", "page.info.message", "page.info.message.%{count}", @meta.image_count, begin: @meta.begin, end: @meta.end)}}</Caption>
              </div>
              <div class="flex-wrap">
                <div class="flex flex-row w-full gap-4" x-data="{ selected_page: {{@meta.page}} }" >
                  <For each={{ page <- 1..Enum.min([page_count(@viewport, @breakpoint), @meta.page_count]) }} >
                    <div
                      class="rounded w-8 h-8 cursor-pointer flex-shrink-0 overflow-hidden"
                      :class="{ 'bg-primary text-white':  selected_page === {{page}}, 'bg-grey5': selected_page  != {{page}} }"
                      x-on:click="selected = {{page}}, $parent.selected = -1"
                      :on-click="select_page"
                      phx-value-page={{ page }}
                    >
                      <div class="flex flex-row items-center justify-center w-full h-full">
                        <div class="text-label font-label" :class="{ 'text-white': selected_page === {{page}}, 'text-grey2': selected_page != {{page}} }">
                          {{ page }}
                        </div>
                      </div>
                    </div>
                  </For>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
