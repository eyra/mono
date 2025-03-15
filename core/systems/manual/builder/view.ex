defmodule Systems.Manual.Builder.View do
  use CoreWeb, :live_component

  alias Systems.Manual

  @impl true
  def update(%{manual: manual}, socket) do
    selected_chapter_id = Map.get(socket.assigns, :selected_chapter_id)

    {
      :ok,
      socket
      |> assign(
        manual: manual,
        selected_chapter_id: selected_chapter_id
      )
      |> update_selected_chapter()
      |> compose_child(:chapter_list)
      |> compose_child(:chapter_form)
      |> compose_child(:page_list)
    }
  end

  def update_selected_chapter(%{assigns: %{manual: %{chapters: []}}} = socket) do
    # If there are no chapters, we don't have a selected chapter
    socket
    |> assign(selected_chapter_id: nil, selected_chapter: nil)
  end

  def update_selected_chapter(
        %{assigns: %{selected_chapter_id: selected_chapter_id, manual: %{chapters: chapters}}} =
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
  def compose(:chapter_list, %{manual: manual, selected_chapter_id: selected_chapter_id}) do
    %{
      module: Manual.Builder.ChapterListView,
      params: %{
        manual: manual,
        selected_chapter_id: selected_chapter_id
      }
    }
  end

  def compose(:chapter_form, %{
        manual: %{chapters: chapters},
        selected_chapter_id: selected_chapter_id
      }) do
    chapter = Enum.find(chapters, fn chapter -> chapter.id == selected_chapter_id end)

    %{
      module: Manual.Builder.ChapterForm,
      params: %{chapter: chapter}
    }
  end

  def compose(:page_list, %{selected_chapter: nil}) do
    nil
  end

  @impl true
  def compose(:page_list, %{selected_chapter: selected_chapter}) do
    %{
      module: Manual.Builder.PageListView,
      params: %{chapter: selected_chapter}
    }
  end

  def handle_event("select_chapter", %{chapter_id: chapter_id}, socket) do
    {
      :noreply,
      socket
      |> assign(selected_chapter_id: chapter_id |> String.to_integer())
      |> update_selected_chapter()
      |> compose_child(:chapter_list)
      |> compose_child(:chapter_form)
      |> compose_child(:page_list)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="manual-builder-view" class="w-full h-full flex flex-col gap-4" phx-hook="LiveContent">
      <div>
        <Text.body>
          <%= dgettext("eyra-manual", "manual.builder.description") %>
        </Text.body>
      </div>
      <div class="flex-grow pb-8">
        <div id="manual-builder-container" class="w-full h-full flex flex-row gap-4 rounded-lg bg-grey5 p-4">
          <!-- Master Sidebar View -->
          <div id="manual-builder-master-sidebar" class="rounded-lg bg-white p-4 w-[480px]">
            <.child name={:chapter_list} fabric={@fabric} />
          </div>

          <!-- Detail View -->
          <div id="manual-builder-detail" class="flex flex-col gap-4 flex-grow">
            <!-- Top View -->
            <div id="manual-builder-top-view" class="rounded-lg bg-white p-4">
              <.child name={:chapter_form} fabric={@fabric} />
            </div>

            <!-- Content View -->
            <div id="manual-builder-content" class="rounded-lg bg-white p-4 flex-grow">
              <.child name={:page_list} fabric={@fabric} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
