defmodule Systems.Manual.ChapterView do
  @moduledoc """
    Chapter View divided into Desktop and Mobile views.
  """

  use CoreWeb, :live_component

  import Systems.Manual.Html, only: [chapter_desktop: 1, chapter_mobile: 1]
  import Core.ImageHelpers, only: [decode_image_info: 1]

  alias Systems.Userflow

  @impl true
  def update(%{chapter: chapter, user: user}, socket) do
    selected_page_id = Map.get(socket.assigns, :selected_page_id, nil)

    {
      :ok,
      socket
      |> assign(chapter: chapter, user: user, selected_page_id: selected_page_id)
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
    |> update_mobile_back_button()
    |> update_desktop_back_button()
    |> update_left_button()
    |> update_right_button()
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

  defp update_mobile_back_button(socket) do
    mobile_back_button = %{
      action: %{type: :send, event: "back"},
      face: %{type: :icon, icon: :overview}
    }

    socket
    |> assign(mobile_back_button: mobile_back_button)
  end

  defp update_desktop_back_button(socket) do
    desktop_back_button = %{
      action: %{type: :send, event: "back"},
      face: %{
        type: :plain,
        label: dgettext("eyra-manual", "chapter.overview"),
        icon: :overview,
        icon_align: :left
      }
    }

    socket
    |> assign(desktop_back_button: desktop_back_button)
  end

  defp update_right_button(%{assigns: %{pages: pages, selected_page: selected_page}} = socket) do
    right_button =
      if last_page?(selected_page, pages) do
        %{
          action: %{type: :send, event: "done"},
          face: %{
            type: :plain,
            label: dgettext("eyra-manual", "chapter.done.button"),
            icon: :done
          }
        }
      else
        %{
          action: %{type: :send, event: "next_page"},
          face: %{
            type: :plain,
            label: dgettext("eyra-manual", "chapter.next.button"),
            icon: :forward
          }
        }
      end

    socket
    |> assign(right_button: right_button)
  end

  defp update_left_button(%{assigns: %{selected_page: selected_page, pages: pages}} = socket) do
    left_button =
      if first_page?(selected_page, pages) do
        nil
      else
        %{
          action: %{type: :send, event: "previous_page"},
          face: %{
            type: :plain,
            label: dgettext("eyra-manual", "chapter.previous.button"),
            icon: :back,
            icon_align: :left
          }
        }
      end

    socket |> assign(left_button: left_button)
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

  def handle_event("back", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "back")
    }
  end

  def handle_event("next_page", _, socket) do
    {
      :noreply,
      socket |> go_to_next_page()
    }
  end

  def handle_event("previous_page", _, socket) do
    {
      :noreply,
      socket |> go_to_previous_page()
    }
  end

  def handle_event("select_page", %{"item" => item_id}, socket) do
    page_id = String.to_integer(item_id)

    {
      :noreply,
      socket
      |> assign(selected_page_id: page_id)
      |> update_selected_page()
      |> update_ui()
    }
  end

  def handle_event("done", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "back")
    }
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
         %{assigns: %{chapter: %{pages: pages}, selected_page_id: selected_page_id, user: user}} =
           socket
       ) do
    %{userflow_step: userflow_step} = current_page(pages, selected_page_id)
    Userflow.Public.mark_visited(userflow_step, user)
    socket
  end

  defp first_page?(%{number: number}, _pages) do
    number == 1
  end

  defp last_page?(%{number: number}, pages) do
    number == Enum.count(pages)
  end

  defp current_page(pages, selected_page_id) do
    Enum.find(pages, &(&1.id == selected_page_id))
  end

  defp next_page(pages, selected_page_id) do
    selected_page_index = Enum.find_index(pages, &(&1.id == selected_page_id))
    next_page_index = selected_page_index + 1

    if Enum.count(pages) > next_page_index do
      pages |> Enum.at(next_page_index)
    else
      pages |> List.first()
    end
  end

  defp previous_page(pages, selected_page_id) do
    selected_page_index = Enum.find_index(pages, &(&1.id == selected_page_id))
    previous_page_index = selected_page_index - 1

    if previous_page_index >= 0 do
      pages |> Enum.at(previous_page_index)
    else
      pages |> List.last()
    end
  end

  defp go_to_next_page(%{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket) do
    next_page = next_page(pages, selected_page_id)

    socket
    |> assign(selected_page_id: next_page.id)
    |> update_selected_page()
    |> mark_selected_page_visited()
    |> update_ui()
  end

  defp go_to_previous_page(
         %{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket
       ) do
    previous_page = previous_page(pages, selected_page_id)

    socket
    |> assign(selected_page_id: previous_page.id)
    |> update_selected_page()
    |> update_ui()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="hidden lg:block">
        <.chapter_desktop
          id={@chapter.id}
          title={@title}
          label={@label}
          pages={@pages}
          selected_page={@selected_page}
          back_button={@desktop_back_button}
          left_button={@left_button}
          right_button={@right_button}
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
          back_button={@mobile_back_button}
          left_button={@left_button}
          right_button={@right_button}
          fullscreen_button={@fullscreen_button}
        />
      </div>
    </div>
    """
  end
end
