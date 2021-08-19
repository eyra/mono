defmodule CoreWeb.ImageCatalogPicker do
  use CoreWeb.UI.LiveComponent

  alias EyraUI.Text.{Title3, BodyLarge, Caption}
  alias EyraUI.Button.SubmitButton
  alias EyraUI.Grid.ImageGrid

  prop(conn, :any, required: true)
  prop(static_path, :any, required: true)
  prop(image_catalog, :any, required: true)
  prop(initial_query, :string, default: "")
  data(query, :string, default: "")
  data(search_results, :list, default: [])
  data(meta, :any)

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded">
      <div class="pl-6 pr-6 pt-6 pb-8 lg:pt-8 lg:pb-10 lg:pr-8 lg:pl-8">
        <div class="flex flex-row">
          <div class="flex-grow">
            <Title3>{{dgettext("eyra-imagecatalog", "search.image.title")}}</Title3>
          </div>
          <button type="button" class="w-button-sm h-button-sm flex-wrap cursor-pointer active:opacity-50" x-on:click="open = false, $parent.$parent.overlay = false">
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
          <div :if={{@search_results != []}}>
            <Spacing value="S" />
            <BodyLarge>{{dngettext("eyra-imagecatalog", "images.found.message", "images.found.message.%{count}",  @meta.image_count )}}</BodyLarge>
            <Spacing value="S" />
            <ImageGrid>
              <div :for={{ {image, index} <- Enum.with_index(@search_results) }}>
                <div
                  id="clickable-area-{{index}}"
                  class="relative w-image-preview h-image-preview bg-grey4 ring-4 hover:ring-primary cursor-pointer rounded overflow-hidden"
                  :class="{ 'ring-primary': selected === {{index}}, 'ring-white': selected != {{index}} }"
                  x-on:click="selected = {{index}}"
                  :on-click="select_image"
                  phx-value-image={{image.id}}
                >
                  <div
                    class="absolute z-10 w-full h-full bg-primary bg-opacity-50"
                    :class="{ 'visible': selected === {{index}}, 'invisible': selected != {{index}} }"
                  />
                  <div
                    class="absolute z-20 w-full h-full"
                    :class="{ 'visible': selected === {{index}}, 'invisible': selected != {{index}} }"
                  >
                    <img class="w-full h-full object-none" src={{ @static_path.(@conn, "/images/checkmark.svg")}} />
                  </div>
                  <div class="w-full h-full">
                    <img class="object-cover w-full h-full image" src={{image.url}} srcset={{image.srcset}}/>
                  </div>
                </div>
              </div>
            </ImageGrid>
            <Spacing value="S" />
            <div class="flex flex-row">
              <div class="flex-grow">
                <Caption text_alignment="left" padding="p-0" margin="m-0" color="text-grey2">{{dngettext("eyra-imagecatalog", "page.info.message", "page.info.message.%{count}", @meta.image_count, begin: @meta.begin, end: @meta.end)}}</Caption>
              </div>
              <div class="flex-wrap">
                <div class="flex flex-row" x-data="{ selected_page: {{@meta.page}} }" >
                  <For each={{ page <- 1..Enum.min([10, @meta.page_count]) }}>
                    <If condition={{ page > 1 }}>
                      <Spacing value="XS" direction="l" />
                    </If>
                    <div
                      class="rounded w-8 h-8 cursor-pointer"
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

  defp search(socket, query, image_catalog, page, page_size \\ 10) do
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
end
