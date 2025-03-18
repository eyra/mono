defmodule Manual.ChapterDesktopView do
  @moduledoc """
   Desktop view of a chapter in a manual. It is using a Master-Detail pattern.
   In the Master view, we have the list of pages.
   In the Detail view, we have the selected page content.
  """

  use CoreWeb, :live_component

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.Line

  alias Systems.Manual

  @impl true
  def update(%{chapter: chapter}, socket) do
    selected_page_id = Map.get(socket.assigns, :selected_page_id, nil)

    {
      :ok,
      socket
      |> assign(
        chapter: chapter,
        selected_page_id: selected_page_id
      )
      |> update_pages()
      |> update_selected_page()
      |> compose_child(:page_list_view)
      |> compose_child(:page_view)
      |> update_buttons()
    }
  end

  @impl true
  def compose(:page_list_view, %{chapter: chapter, selected_page_id: selected_page_id}) do
    %{
      module: Manual.PageListView,
      params: %{
        chapter: chapter,
        selected_page_id: selected_page_id
      }
    }
  end

  @impl true
  def compose(:page_view, %{chapter: chapter, selected_page: selected_page}) do
    %{
      module: Manual.PageView,
      params: %{
        page: selected_page,
        title: chapter.title,
        tag: chapter.userflow_step.group
      }
    }
  end

  def update_pages(%{assigns: %{chapter: %{pages: [_ | _] = pages}}} = socket) do
    socket |> assign(pages: pages |> Enum.sort_by(& &1.userflow_step.order))
  end

  def update_pages(socket) do
    socket |> assign(pages: [])
  end

  def update_selected_page(%{assigns: %{pages: []}} = socket) do
    socket
  end

  def update_selected_page(
        %{assigns: %{selected_page_id: selected_page_id, pages: pages}} = socket
      ) do
    selected_page =
      case Enum.find(pages, fn page -> page.id == selected_page_id end) do
        nil ->
          pages |> List.first()

        page ->
          page
      end

    socket |> assign(selected_page: selected_page, selected_page_id: selected_page.id)
  end

  def update_buttons(%{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket) do
    back_button = %{
      action: %{type: :send, event: "back"},
      face: %{type: :secondary, label: dgettext("eyra-manual", "chapter.back.button")}
    }

    next_button =
      if next_page(pages, selected_page_id) != nil do
        %{
          action: %{type: :send, event: "next_page"},
          face: %{
            type: :plain,
            label: dgettext("eyra-manual", "chapter.next.button"),
            icon: :forward
          }
        }
      else
        nil
      end

    socket |> assign(back_button: back_button, next_button: next_button)
  end

  def handle_event("select_page", %{page_id: page_id}, socket) do
    {
      :noreply,
      socket
      |> assign(selected_page_id: page_id)
      |> update_selected_page()
      |> update_child(:page_list_view)
      |> update_child(:page_view)
      |> update_buttons()
    }
  end

  def handle_event("back", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "back")
    }
  end

  def handle_event("next_page", _, socket) do
    {
      :noreply,
      socket
      |> go_to_next_page()
    }
  end

  defp go_to_next_page(%{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket) do
    next_page =
      if next_page = next_page(pages, selected_page_id) do
        next_page
      else
        pages |> List.last()
      end

    socket
    |> assign(selected_page_id: next_page.id)
    |> update_selected_page()
    |> update_child(:page_list_view)
    |> update_child(:page_view)
    |> update_buttons()
  end

  defp next_page(pages, selected_page_id) do
    selected_page_index = Enum.find_index(pages, &(&1.id == selected_page_id))
    next_page_index = selected_page_index + 1

    if Enum.count(pages) > next_page_index do
      pages |> Enum.at(next_page_index)
    else
      nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-col gap-8">
      <div class="flex-1 w-full h-full flex flex-row gap-6">
        <!-- Master View -->
        <div class="flex-shrink-0 w-[296px] h-full">
          <div class="flex flex-col gap-8">
            <div class="flex flex-col gap-4">
              <div class="flex flex-col gap-2">
                <Text.title7 color="text-grey2"><%= @chapter.title %></Text.title7>
                <%= if @chapter.userflow_step.group do %>
                  <div>
                    <div class="flex flex-row">
                      <.tag text={@chapter.userflow_step.group} />
                    </div>
                  </div>
                <% end %>
              </div>
              <.line />
            </div>
            <.child name={:page_list_view} fabric={@fabric} />
            <div class="flex flex-col gap-4">
              <.line />
              <Button.dynamic {@back_button} />
            </div>
          </div>
        </div>
        <!-- Detail View -->
        <div class="flex-grow h-full flex flex-col gap-8 mb-8">
          <.child name={:page_view} fabric={@fabric} />
          <%= if @next_button do %>
            <Button.dynamic {@next_button} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
