defmodule Systems.Manual.Builder.PageListView do
  use CoreWeb, :live_component

  import Systems.Manual.Builder.Html, only: [page_list_item: 1]

  alias Systems.Manual

  @impl true
  def update(%{chapter: chapter}, socket) do
    selected_page_id = Map.get(socket.assigns, :selected_page_id)
    deselected = Map.get(socket.assigns, :deselected)

    {
      :ok,
      socket
      |> assign(
        chapter: chapter,
        selected_page_id: selected_page_id,
        deselected: deselected
      )
      |> update_pages()
      |> update_selected_page_id()
      |> update_list_items()
      |> update_button()
      |> compose_child(:page_form)
    }
  end

  def update_pages(%{assigns: %{chapter: %{pages: [_ | _] = pages}}} = socket) do
    socket |> assign(pages: pages |> Enum.sort_by(& &1.userflow_step.order))
  end

  def update_pages(socket) do
    socket |> assign(pages: [])
  end

  def update_button(socket) do
    button = %{
      action: %{type: :send, event: "create_page"},
      face: %{type: :secondary, label: dgettext("eyra-manual", "create.page.button"), icon: :add}
    }

    socket |> assign(button: button)
  end

  def update_selected_page_id(%{assigns: %{deselected: true}} = socket) do
    socket
  end

  def update_selected_page_id(%{assigns: %{pages: []}} = socket) do
    # Disable selection if there are no pages
    socket |> assign(selected_page_id: nil)
  end

  def update_selected_page_id(%{assigns: %{pages: [page | _], selected_page_id: nil}} = socket) do
    # Select the first page if no page is selected
    socket
    |> assign(selected_page_id: page.id)
  end

  def update_selected_page_id(
        %{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket
      ) do
    # Select the page if it exists, otherwise select the first page
    page =
      case Enum.find(pages, fn page -> page.id == selected_page_id end) do
        nil ->
          Enum.at(pages, 0)

        page ->
          page
      end

    socket |> assign(selected_page_id: page.id)
  end

  @impl true
  def compose(:page_form, %{pages: pages, selected_page_id: selected_page_id}) do
    page = Enum.find(pages, fn page -> page.id == selected_page_id end)

    %{
      module: Systems.Manual.Builder.PageForm,
      params: %{page: page}
    }
  end

  def update_list_items(%{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket) do
    list_items =
      pages
      |> Enum.with_index()
      |> Enum.map(fn {page, index} ->
        map_page_to_list_item(page, selected_page_id, index)
      end)

    socket
    |> assign(list_items: list_items)
  end

  def map_page_to_list_item(page, selected_page_id, index) do
    up_button = %{
      action: %{type: :send, event: "up", item: page.id},
      face: %{type: :icon, icon: :arrow_up}
    }

    delete_button = %{
      action: %{type: :send, event: "delete_page", item: page.id},
      face: %{type: :icon, icon: :delete_red}
    }

    buttons =
      if index == 0 do
        [delete_button]
      else
        [up_button, delete_button]
      end

    %{
      id: page.id,
      title: page.title,
      active: page.id == selected_page_id,
      number: index + 1,
      buttons: buttons
    }
  end

  def handle_event("create_page", _params, %{assigns: %{chapter: chapter}} = socket) do
    Manual.Public.add_page(chapter)
    {:noreply, socket}
  end

  def handle_event("delete_page", %{"item" => page_id}, %{assigns: %{pages: pages}} = socket) do
    page = Enum.find(pages, fn page -> page.id == page_id |> String.to_integer() end)
    Manual.Public.delete_page(page)
    {:noreply, socket}
  end

  def handle_event(
        "select_page",
        %{"item" => page_id},
        %{assigns: %{selected_page_id: selected_page_id}} = socket
      ) do
    page_id_int = page_id |> String.to_integer()

    # If the page is already selected, deselect it by setting selected_page_id to nil
    new_selected_id = if page_id_int == selected_page_id, do: nil, else: page_id_int

    # Explicitly track if the user deselected a page
    deselected = new_selected_id == nil

    {
      :noreply,
      socket
      |> assign(selected_page_id: new_selected_id)
      |> assign(deselected: deselected)
      |> update_list_items()
      |> update_child(:page_form)
    }
  end

  def handle_event("up", %{"item" => page_id}, %{assigns: %{pages: pages}} = socket) do
    page = Enum.find(pages, fn page -> page.id == page_id |> String.to_integer() end)
    Manual.Public.move_page(page, :up)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3>
        <%= dgettext("eyra-manual", "builder.pages.list.title") %>
      </Text.title3>
      <.spacing value="S" />
      <%= if not Enum.empty?(@list_items) do %>
        <div class="flex flex-col gap-2 mb-4">
          <%= for list_item <- @list_items do %>
            <div>
              <%= if list_item.active do %>
                <.page_list_item {list_item} target={@myself} />
                <.child name={:page_form} fabric={@fabric} />

              <% else %>
                <.page_list_item {list_item} target={@myself} />
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
      <Button.dynamic_bar buttons={[@button]} />
    </div>
    """
  end
end
