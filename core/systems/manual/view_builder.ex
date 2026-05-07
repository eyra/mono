defmodule Systems.Manual.ViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Manual

  @doc """
  Builds view model for Manual.View.
  Always builds chapter_list, conditionally builds chapter based on selection.
  Receives chapter and page directly from {:user_state, [:chapter, :page]} dependency.
  """
  def view_model(manual, %{
        title: title,
        current_user: user,
        presentation: presentation,
        user_state: user_state
      }) do
    chapter_id = user_state[:chapter]
    page_id = user_state[:page]
    chapters = get_chapters(manual)
    selected_chapter = find_selected_chapter(chapters, chapter_id)

    buttons = build_toolbar_buttons(selected_chapter, page_id)

    %{
      manual: manual,
      title: title,
      user: user,
      selected_chapter_id: chapter_id,
      chapters: chapters,
      selected_chapter: selected_chapter,
      chapter_list_view: build_chapter_list_view(manual, title, chapter_id),
      chapter_view: build_chapter_view(manual, selected_chapter, user, page_id),
      toolbar: build_toolbar(presentation, buttons),
      buttons: buttons
    }
  end

  defp get_chapters(%{chapters: [_ | _] = chapters}) do
    chapters |> Enum.sort_by(& &1.userflow_step.order)
  end

  defp get_chapters(_), do: []

  defp find_selected_chapter([], _selected_chapter_id), do: nil
  defp find_selected_chapter(_chapters, nil), do: nil

  defp find_selected_chapter(chapters, selected_chapter_id) do
    case Enum.find(chapters, &(&1.id == selected_chapter_id)) do
      nil -> List.first(chapters)
      chapter -> chapter
    end
  end

  defp build_chapter_list_view(manual, title, selected_chapter_id) do
    LiveNest.Element.prepare_live_component(
      :chapter_list,
      Manual.ChapterListView,
      manual: manual,
      title: title,
      selected_chapter_id: selected_chapter_id
    )
  end

  # Returns nil when no chapter selected
  defp build_chapter_view(_manual, nil, _user, _page_id), do: nil

  # Returns chapter view spec when chapter is selected
  defp build_chapter_view(manual, selected_chapter, user, page_id) do
    LiveNest.Element.prepare_live_component(
      :chapter,
      Manual.ChapterView,
      manual_id: manual.id,
      chapter: selected_chapter,
      user: user,
      page_id: page_id
    )
  end

  # No buttons: no toolbar
  defp build_toolbar(_presentation, []), do: nil

  # Modal presentation: no local toolbar (buttons published to parent modal)
  defp build_toolbar(:modal, _buttons), do: nil

  # Embedded presentation: build local toolbar
  defp build_toolbar(_presentation, buttons) do
    %{buttons: buttons}
  end

  # No chapter selected: no buttons
  defp build_toolbar_buttons(nil, _page_id), do: []

  # Chapter selected: build navigation buttons
  defp build_toolbar_buttons(selected_chapter, page_id) do
    pages = get_pages(selected_chapter)
    selected_page = find_selected_page(pages, page_id)
    build_navigation_buttons(pages, selected_page)
  end

  defp get_pages(%{pages: [_ | _] = pages}) do
    pages |> Enum.sort_by(& &1.userflow_step.order)
  end

  defp get_pages(_), do: []

  defp find_selected_page([], _page_id), do: nil
  defp find_selected_page(pages, nil), do: List.first(pages)

  defp find_selected_page(pages, page_id) do
    case Enum.find(pages, &(&1.id == page_id)) do
      nil -> List.first(pages)
      page -> page
    end
  end

  defp build_navigation_buttons(pages, selected_page) do
    page_index = Enum.find_index(pages, &(&1.id == selected_page.id)) || 0
    page_count = Enum.count(pages)
    first_page? = page_index == 0
    last_page? = page_index == page_count - 1

    back_button = %{
      action: %{type: :send, event: if(first_page?, do: "back", else: "previous_page")},
      face: %{
        type: :plain,
        label: dgettext("eyra-manual", "chapter.previous.button"),
        icon: :back,
        icon_align: :left
      }
    }

    right_button =
      if last_page? do
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

    [back_button, right_button]
  end
end
