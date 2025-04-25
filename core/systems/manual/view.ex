defmodule Systems.Manual.View do
  use CoreWeb, :live_component

  alias Frameworks.Utility.UserState
  alias Systems.Manual

  @impl true
  def update(
        %{manual: manual, title: title, user: user, user_state_data: user_state_data},
        socket
      ) do
    user_state_key = "manual-#{manual.id}-selected-chapter-id"
    user_state_value = UserState.integer_value(user_state_data, user_state_key)
    selected_chapter_id = Map.get(socket.assigns, :selected_chapter_id, user_state_value)

    {
      :ok,
      socket
      |> assign(
        manual: manual,
        title: title,
        user: user,
        selected_chapter_id: selected_chapter_id,
        user_state_key: user_state_key,
        user_state_data: user_state_data
      )
      |> update_chapters()
      |> update_selected_chapter()
      |> compose_child(:chapter_list)
      |> compose_child(:chapter)
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

  def compose(:chapter, %{
        selected_chapter: selected_chapter,
        user: user,
        manual: manual,
        user_state_data: user_state_data
      }) do
    %{
      module: Manual.ChapterView,
      params: %{
        manual_id: manual.id,
        chapter: selected_chapter,
        user: user,
        user_state_data: user_state_data
      }
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

  def handle_event("close", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "close")
    }
  end

  def handle_event("done", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "done")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="manual_view" class="w-full h-full" phx-hook="UserState" data-key={@user_state_key} data-value={@selected_chapter_id} >
      <%= if Fabric.exists?(@fabric, :chapter) do %>
        <.child name={:chapter} fabric={@fabric} />
      <% else %>
        <.child name={:chapter_list} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
