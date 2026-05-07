defmodule Systems.Manual.ChapterListView do
  use CoreWeb, :live_component

  import Systems.Manual.Html

  alias Systems.Manual

  @impl true
  def update(
        %{id: id, manual: manual, title: title, selected_chapter_id: selected_chapter_id},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        manual: manual,
        title: title,
        selected_chapter_id: selected_chapter_id
      )
      |> update_chapters()
      |> update_chapter_items()
    }
  end

  def update_chapters(%{assigns: %{manual: %{chapters: [_ | _] = chapters}}} = socket) do
    socket |> assign(chapters: chapters |> Enum.sort_by(& &1.userflow_step.order))
  end

  def update_chapters(socket) do
    socket |> assign(chapters: [])
  end

  def update_chapter_items(%{assigns: %{chapters: chapters}} = socket) do
    chapter_items =
      chapters
      |> Enum.with_index()
      |> Enum.map(&map_chapter_to_item/1)

    socket |> assign(chapter_items: chapter_items)
  end

  def map_chapter_to_item(
        {%Manual.ChapterModel{id: id, title: title, userflow_step: %{group: group}}, index}
      ) do
    %{
      id: id,
      title: title,
      tag: group,
      number: index + 1
    }
  end

  def handle_event("select_chapter", %{"item" => chapter_id}, %{assigns: %{id: id}} = socket) do
    chapter_id_int = String.to_integer(chapter_id)
    source = %{id: id, module: __MODULE__}

    {:noreply,
     publish_event(socket, {:select_chapter, %{chapter_id: chapter_id_int, source: source}})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4" data-testid="chapter-list-view">
      <div class="font-title7 text-title7 text-grey2">
          <%= dgettext("eyra-manual", "chapter.overview") %>
      </div>
      <div class="font-title5 text-title5 sm:font-title2 sm:text-title2"><%= @title %></div>
      <div class="flex flex-col sm:gap-2">
        <.chapter_list items={@chapter_items} selected_chapter_id={@selected_chapter_id} target={@myself} />
      </div>
    </div>
    """
  end
end
