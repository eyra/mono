defmodule CoreWeb.UI.ImageCatalogPicker do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Image

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

  @defaults [
    viewport: nil,
    breakpoint: nil,
    initial_query: "",
    target: "",
    search_results: nil
  ]

  @impl true
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

  @impl true
  def update(
        %{
          id: id,
          static_path: static_path,
          image_catalog: image_catalog
        } = props,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(static_path: static_path)
      |> assign(image_catalog: image_catalog)
      |> update_defaults(props, @defaults)
      |> update_close_button()
    }
  end

  defp update_close_button(%{assigns: %{myself: myself}} = socket) do
    close_button = %{
      action: %{type: :send, event: "close", target: myself},
      face: %{type: :icon, icon: :close}
    }

    socket |> assign(close_button: close_button)
  end

  @impl true
  def handle_event(
        "search",
        %{"q" => query},
        %{assigns: %{image_catalog: image_catalog}} = socket
      ) do
    search(socket, query, image_catalog, 1)
  end

  @impl true
  def handle_event(
        "select_page",
        %{"page" => page},
        %{assigns: %{query: query, image_catalog: image_catalog}} = socket
      ) do
    search(socket, query, image_catalog, String.to_integer(page))
  end

  @impl true
  def handle_event("select_image", %{"image" => image_id}, %{assigns: %{id: id}} = socket) do
    send(self(), {id, image_id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("close", _, %{assigns: %{id: id}} = socket) do
    send(self(), {id, :close})
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded">
      <div class="pl-6 pr-6 pt-6 pb-8 lg:pt-8 lg:pb-10 lg:pr-8 lg:pl-8">
        <div class="flex flex-row">
          <div>
            <Text.title3><%= dgettext("eyra-imagecatalog", "search.image.title") %></Text.title3>
          </div>
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
        </div>
        <div x-data="{ selected: -1 }">
          <.form id="image_catalog_picker_form" :let={_form} for={%{}} phx-submit="search" phx-target={@myself} >
            <div class="flex flex-row">
              <input
                value={@initial_query}
                class="text-grey1 text-bodymedium font-body pl-3 pr-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-48px"
                name="q"
                type="search"
              />
              <.spacing value="XS" direction="l" />
              <Button.submit
                label={"#{dgettext("eyra-imagecatalog", "search.image.button")}"}
                alpine_onclick="selected = -1"
              />
            </div>
          </.form>

          <%= if @search_results do %>
            <%= if Enum.empty?(@search_results) do %>
              <%= if @query != "" do %>
                <div>
                  <.spacing value="S" />
                  <Text.body_large><%= dgettext("eyra-imagecatalog", "no.results.found.message") %></Text.body_large>
                </div>
              <% end %>
            <% else %>
              <div>
                <.spacing value="S" />
                <Text.body_large>{dngettext(
                    "eyra-imagecatalog",
                    "images.found.message",
                    "images.found.message.%{count}",
                    @meta.image_count
                  )}</Text.body_large>
                <.spacing value="S" />
                <Grid.image gap={gap(@viewport, @breakpoint)}>
                  <%= for {image, index} <- Enum.with_index(@search_results) do %>
                    <div>
                      <Image.grid {image} index={index} target={@myself} />
                    </div>
                  <% end %>
                </Grid.image>
                <.spacing value="S" />
                <div class="flex flex-row">
                  <div class="flex-grow">
                    <Text.caption text_alignment="left" padding="p-0" margin="m-0" color="text-grey2">{dngettext(
                        "eyra-imagecatalog",
                        "page.info.message",
                        "page.info.message.%{count}",
                        @meta.image_count,
                        begin: @meta.begin,
                        end: @meta.end
                      )}</Text.caption>
                  </div>
                  <div class="flex-wrap">
                    <div class="flex flex-row w-full gap-4" x-data={"{ selected_page: #{@meta.page} }"}>
                      <%= for page <- 1..Enum.min([page_count(@viewport, @breakpoint), @meta.page_count]) do %>
                        <div
                          class="rounded w-8 h-8 cursor-pointer flex-shrink-0 overflow-hidden"
                          x-bind:class={"{ 'bg-primary text-white':  selected_page === #{page}, 'bg-grey5': selected_page  != #{page} }"}
                          x-on:click={"selected = #{page}, $parent.selected = -1"}
                          x-bindphx-click="select_page"
                          phx-value-page={page}
                        >
                          <div class="flex flex-row items-center justify-center w-full h-full">
                            <div
                              class="text-label font-label"
                              x-bind:class={"{ 'text-white': selected_page === #{page}, 'text-grey2': selected_page != #{page} }"}
                            >
                              {page}
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
