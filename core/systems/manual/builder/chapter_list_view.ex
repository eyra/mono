defmodule Systems.Manual.Builder.ChapterListView do
  use CoreWeb, :live_component

  import Systems.Manual.Builder.Html, only: [chapter_list: 1]

  alias Systems.Manual

  @impl true
  def update(%{manual: manual, selected_chapter_id: selected_chapter_id}, socket) do
    {
      :ok,
      socket
      |> assign(
        manual: manual,
        selected_chapter_id: selected_chapter_id
      )
      |> update_chapters()
      |> update_chapter_items()
      |> update_button()
    }
  end

  def update_chapters(%{assigns: %{manual: %{chapters: chapters}}} = socket) do
    socket |> assign(chapters: chapters |> Enum.sort_by(& &1.userflow_step.order))
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
    up_button = %{
      action: %{type: :send, event: "up_chapter", item: id},
      face: %{type: :icon, icon: :arrow_up}
    }

    delete_button = %{
      action: %{type: :send, event: "delete_chapter", item: id},
      face: %{type: :icon, icon: :delete_red}
    }

    buttons =
      if index == 0 do
        [delete_button]
      else
        [up_button, delete_button]
      end

    %{
      id: id,
      title: title,
      tag: group,
      buttons: buttons,
      number: index + 1
    }
  end

  def update_button(socket) do
    button = %{
      action: %{type: :send, event: "create_chapter"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-manual", "create.chapter.button"),
        icon: :add
      }
    }

    socket |> assign(button: button)
  end

  def handle_event("create_chapter", _params, %{assigns: %{manual: manual}} = socket) do
    Manual.Public.add_chapter(manual)
    {:noreply, socket}
  end

  def handle_event(
        "delete_chapter",
        %{"item" => chapter_id},
        %{assigns: %{chapters: chapters}} = socket
      ) do
    chapter =
      Enum.find(chapters, fn chapter -> chapter.id == chapter_id |> String.to_integer() end)

    Manual.Public.remove_chapter(chapter)
    {:noreply, socket}
  end

  def handle_event("select_chapter", %{"item" => chapter_id}, socket) do
    {:noreply, socket |> send_event(:parent, "select_chapter", %{chapter_id: chapter_id})}
  end

  def handle_event(
        "up_chapter",
        %{"item" => chapter_id},
        %{assigns: %{chapters: chapters}} = socket
      ) do
    chapter =
      Enum.find(chapters, fn chapter -> chapter.id == chapter_id |> String.to_integer() end)

    Manual.Public.move_chapter(chapter, :up)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2>
        <%= dgettext("eyra-manual", "builder.chapter.list.title") %>
      </Text.title2>
      <.spacing value="M" />
      <%= if not Enum.empty?(@chapter_items) do %>
        <div class="mb-4">
          <.chapter_list chapters={@chapter_items} selected_chapter_id={@selected_chapter_id} target={@myself} />
        </div>
      <% end %>
      <Button.dynamic {@button} />
    </div>
    """
  end
end
