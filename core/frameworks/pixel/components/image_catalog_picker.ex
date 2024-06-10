defmodule Frameworks.Pixel.ImageCatalogPicker do
  use CoreWeb, :live_component

  import CoreWeb.UI.Dialog
  import CoreWeb.LiveDefaults

  alias Frameworks.Pixel.Text
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
          image_catalog: image_catalog,
          state: state
        } = props,
        socket
      ) do
    {
      :ok,
      socket
      |> update_defaults(props, @defaults)
      |> update_state(state)
      |> assign(
        id: id,
        static_path: static_path,
        image_catalog: image_catalog
      )
      |> update_title()
      |> update_buttons()
      |> initial_search()
    }
  end

  def update_state(%{} = socket, nil) do
    socket
    |> assign(
      query: nil,
      selected_page: 1,
      selected_image: nil
    )
  end

  def update_state(%{} = socket, %{
        query: query,
        selected_page: selected_page,
        selected_image: selected_image
      }) do
    socket
    |> assign(
      initial_query: query,
      query: query,
      selected_page: selected_page,
      selected_image: selected_image
    )
  end

  defp initial_search(%{assigns: %{initial_query: nil}} = socket) do
    socket
  end

  defp initial_search(%{assigns: %{initial_query: ""}} = socket) do
    socket
  end

  defp initial_search(
         %{
           assigns: %{
             initial_query: initial_query,
             image_catalog: image_catalog,
             selected_page: selected_page
           }
         } = socket
       ) do
    {:noreply, socket} =
      socket
      |> assign(selected_page: selected_page)
      |> search(initial_query, image_catalog, selected_page)

    socket
  end

  defp update_title(socket) do
    socket |> assign(:title, dgettext("eyra-imagecatalog", "search.image.title"))
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket, buttons: form_dialog_buttons(myself))
  end

  @impl true
  def handle_event(
        "search",
        %{"q" => query},
        %{assigns: %{image_catalog: image_catalog}} = socket
      ) do
    socket
    |> assign(selected_page: 1)
    |> search(query, image_catalog, 1)
  end

  @impl true
  def handle_event(
        "select_page",
        %{"page" => page},
        %{assigns: %{query: query, image_catalog: image_catalog}} = socket
      ) do
    socket
    |> assign(selected_page: String.to_integer(page))
    |> search(query, image_catalog, String.to_integer(page))
  end

  @impl true
  def handle_event("submit", _payload, %{assigns: %{selected_image: nil}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit",
        _payload,
        %{assigns: %{query: query, selected_page: selected_page, selected_image: selected_image}} =
          socket
      ) do
    {:noreply,
     socket
     |> send_event(:parent, "finish", %{
       image_id: selected_image,
       state: %{query: query, selected_page: selected_page, selected_image: selected_image}
     })}
  end

  @impl true
  def handle_event("cancel", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "finish")}
  end

  @impl true
  def handle_event("select_image", %{"image" => image_id}, socket) do
    {:noreply, socket |> assign(selected_image: image_id)}
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
    <div>
      <.dialog {%{title: @title, buttons: @buttons}}>
        <.form id="image_catalog_picker_form" :let={_form} for={%{}} phx-submit="search" phx-target={@myself} >
          <div class="flex flex-row">
            <input
              value={@initial_query}
              class="text-grey1 text-bodymedium font-body pl-3 pr-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-48px"
              name="q"
              type="search"
            />
            <.spacing value="XS" direction="l" />
            <Button.submit label={"#{dgettext("eyra-imagecatalog", "search.image.button")}"} target={@myself} />
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
              <Text.body_large><%= dngettext(
                  "eyra-imagecatalog",
                  "images.found.message",
                  "images.found.message.%{count}",
                  @meta.image_count
                ) %></Text.body_large>
              <.spacing value="S" />
              <Grid.image gap={gap(@viewport, @breakpoint)}>
                <%= for {image, index} <- Enum.with_index(@search_results) do %>
                  <div class="h-[150px]">
                    <Image.grid {image} index={index} target={@myself} selected={@selected_image == image.id} />
                  </div>
                <% end %>
              </Grid.image>
              <.spacing value="S" />
              <div class="flex flex-row">
                <div class="flex-grow">
                  <Text.caption text_alignment="left" padding="p-0" margin="m-0" color="text-grey2"><%= dngettext(
                      "eyra-imagecatalog",
                      "page.info.message",
                      "page.info.message.%{count}",
                      @meta.image_count,
                      begin: @meta.begin,
                      end: @meta.end
                    ) %></Text.caption>
                </div>
                <div class="flex-wrap">
                  <div class="flex flex-row w-full gap-4"}>
                    <%= for page <- 1..Enum.min([page_count(@viewport, @breakpoint), @meta.page_count]) do %>
                      <div
                        class={"rounded w-8 h-8 cursor-pointer flex-shrink-0 overflow-hidden #{if @selected_page == page do "bg-primary text-white" else "bg-grey5 text-grey2" end} hover:bg-primary hover:text-white"}
                        phx-click="select_page"
                        phx-value-page={page}
                        phx-target={@myself}
                      >
                        <div class={"flex flex-row items-center justify-center w-full h-full"}>
                          <div class="text-label font-label"><%= page %></div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </.dialog>
    </div>
    """
  end
end
