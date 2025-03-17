defmodule Systems.Manual.View do
  use CoreWeb, :live_component

  alias Systems.Manual

  @impl true
  def update(%{manual: manual, title: title}, socket) do
    selected_chapter_id = Map.get(socket.assigns, :selected_chapter_id, nil)

    {
      :ok,
      socket
      |> assign(
        manual: manual,
        title: title,
        selected_chapter_id: selected_chapter_id
      )
      |> update_chapters()
      |> update_selected_chapter()
      |> compose_child(:chapter_list)
      |> update_child(:chapter)
    }
  end

  def update_chapters(%{assigns: %{manual: %{chapters: [_ | _] = chapters}}} = socket) do
    socket |> assign(chapters: chapters |> Enum.sort_by(& &1.userflow_step.order))
  end

  def update_chapters(socket) do
    socket |> assign(chapters: [])
  end

  def update_selected_chapter(%{assigns: %{chapters: []}} = socket) do
    # If there are no chapters, we don't have a selected chapter
    socket
    |> assign(selected_chapter_id: nil, selected_chapter: nil)
  end

  def update_selected_chapter(%{assigns: %{selected_chapter_id: nil}} = socket) do
    socket
    |> assign(selected_chapter: nil)
  end

  def update_selected_chapter(
        %{assigns: %{chapters: chapters, selected_chapter_id: selected_chapter_id}} =
          socket
      ) do
    selected_chapter =
      case Enum.find(chapters, fn chapter -> chapter.id == selected_chapter_id end) do
        nil ->
          chapters |> List.first()

        chapter ->
          chapter
      end

    socket
    |> assign(selected_chapter_id: selected_chapter.id, selected_chapter: selected_chapter)
  end

  @impl true
  def compose(:chapter_list, %{
        manual: manual,
        title: title,
        selected_chapter_id: selected_chapter_id
      }) do
    %{
      module: Manual.ChapterListView,
      params: %{
        manual: manual,
        title: title,
        selected_chapter_id: selected_chapter_id
      }
    }
  end

  def compose(:chapter, %{selected_chapter: nil}) do
    nil
  end

  def compose(:chapter, %{selected_chapter: selected_chapter}) do
    %{
      module: Manual.ChapterView,
      params: %{chapter: selected_chapter}
    }
  end

  def handle_event("select_chapter", %{chapter_id: chapter_id}, socket) do
    {
      :noreply,
      socket
      |> assign(selected_chapter_id: chapter_id)
      |> update_selected_chapter()
      |> compose_child(:chapter)
    }
  end

  def handle_event("back", _, socket) do
    {
      :noreply,
      socket
      |> assign(selected_chapter_id: nil, selected_chapter: nil)
      |> hide_child(:chapter)
      |> update_child(:chapter_list)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4">
      <%= if Fabric.exists?(@fabric, :chapter) do %>
        <.child name={:chapter} fabric={@fabric} />
      <% else %>
        <.child name={:chapter_list} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
