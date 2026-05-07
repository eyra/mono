defmodule Systems.Manual.ChapterView do
  @moduledoc """
    Chapter View divided into Desktop and Mobile views.
  """

  use CoreWeb, :live_component
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Manual.Html, only: [chapter_desktop: 1, chapter_mobile: 1]
  import Core.ImageHelpers, only: [decode_image_info: 1]

  alias Systems.Userflow

  @impl true
  def update(
        %{id: id, manual_id: manual_id, chapter: chapter, user: user, page_id: page_id},
        socket
      ) do
    # Use page_id from params, fallback to current assign
    page_id = page_id || Map.get(socket.assigns, :page_id)

    {
      :ok,
      socket
      |> assign(
        id: id,
        manual_id: manual_id,
        chapter: chapter,
        user: user,
        page_id: page_id
      )
      |> mark_chapter_visited()
      |> update_ui()
    }
  end

  def update_ui(socket) do
    socket
    |> update_title()
    |> update_label()
    |> update_pages()
    |> update_selected_page()
    |> mark_selected_page_visited()
    |> update_indicator()
    |> update_fullscreen_button()
  end

  def update_title(%{assigns: %{chapter: %{title: title}}} = socket) do
    socket |> assign(title: title)
  end

  def update_label(%{assigns: %{chapter: %{userflow_step: %{group: group}}}} = socket) do
    socket |> assign(label: group)
  end

  def update_indicator(%{assigns: %{pages: pages, selected_page: %{number: number}}} = socket) do
    socket
    |> assign(
      indicator:
        dgettext("eyra-manual", "chapter.page.indicator",
          count: Enum.count(pages),
          current: number
        )
    )
  end

  def update_pages(%{assigns: %{chapter: %{pages: [_ | _] = pages}}} = socket) do
    pages =
      pages
      |> Enum.sort_by(& &1.userflow_step.order)
      |> Enum.with_index()
      |> Enum.map(fn {%{image: image, id: id, title: title, text: text}, index} ->
        %{
          id: id,
          title: title,
          image_info: decode_image_info(image),
          text: text,
          number: index + 1
        }
      end)

    socket |> assign(pages: pages)
  end

  def update_pages(socket) do
    socket |> assign(pages: [])
  end

  def update_selected_page(%{assigns: %{pages: []}} = socket) do
    socket
  end

  def update_selected_page(%{assigns: %{page_id: page_id, pages: pages}} = socket) do
    selected_page =
      case Enum.find(pages, fn page -> page.id == page_id end) do
        nil ->
          pages |> List.first()

        page ->
          page
      end

    socket |> assign(selected_page: selected_page, page_id: selected_page.id)
  end

  defp update_fullscreen_button(socket) do
    fullscreen_button = %{
      action: %{type: :send, event: "fullscreen"},
      face: %{
        type: :plain,
        label: dgettext("eyra-manual", "image.fullscreen.button"),
        icon: :zoom,
        icon_align: :left,
        text_color: "text-primary"
      }
    }

    socket |> assign(fullscreen_button: fullscreen_button)
  end

  def handle_event("select_page", %{"item" => item_id}, socket) do
    page_id = String.to_integer(item_id)
    {:noreply, publish_event(socket, {:page_changed, %{page_id: page_id}})}
  end

  def handle_event("fullscreen", _, socket) do
    # can be ignored, is handled by the FullscreenImage hook in fullscreen_image.js
    {:noreply, socket}
  end

  defp mark_chapter_visited(
         %{assigns: %{chapter: %{userflow_step: userflow_step}, user: user}} = socket
       ) do
    Userflow.Public.mark_visited(userflow_step, user)
    socket
  end

  defp mark_selected_page_visited(
         %{assigns: %{chapter: %{pages: pages}, page_id: page_id, user: user}} =
           socket
       ) do
    %{userflow_step: userflow_step} = current_page(pages, page_id)
    Userflow.Public.mark_visited(userflow_step, user)
    socket
  end

  defp current_page(pages, page_id) do
    Enum.find(pages, &(&1.id == page_id))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="manual_chapter_view" data-testid="chapter-view">
      <div class="hidden lg:block">
        <.chapter_desktop
          id={@chapter.id}
          title={@title}
          label={@label}
          pages={@pages}
          selected_page={@selected_page}
          fullscreen_button={@fullscreen_button}
          select_page_event="select_page"
          select_page_target={@myself}
        />
      </div>
      <div class="block lg:hidden">
        <.chapter_mobile
          id={@chapter.id}
          title={@title}
          label={@label}
          indicator={@indicator}
          selected_page={@selected_page}
          fullscreen_button={@fullscreen_button}
        />
      </div>
    </div>
    """
  end
end
