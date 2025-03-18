defmodule Systems.Manual.Builder.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.NumberIcon

  attr(:chapters, :list, required: true)
  attr(:selected_chapter_id, :integer, default: nil)
  attr(:target, :any, required: true)

  def chapter_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <%= for chapter <- @chapters do %>
        <.chapter_list_item {chapter} selected={@selected_chapter_id == chapter.id} target={@target} />
      <% end %>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:selected, :boolean, default: false)
  attr(:target, :any, required: true)
  attr(:number, :integer, required: true)
  attr(:buttons, :list, required: true)

  def chapter_list_item(assigns) do
    ~H"""
    <div
      class={"p-4 rounded-lg border cursor-pointer #{if @selected do "bg-grey6 border-grey4" else "hover:bg-grey6 border-white" end} "}
      phx-click="select_chapter"
      phx-value-item={@id}
      phx-target={@target}
    >
      <div class="flex flex-col gap-4">
        <div class="flex flex-row gap-4">
          <div class="flex flex-row gap-4">
            <.number_icon number={@number} active={@selected} />
            <div class="flex flex-col gap-2">
              <div class="mt-[2px]">
                <Text.title6 margin=""><%= @title %></Text.title6>
              </div>
              <%= if @tag do %>
                <div class="flex flex-row">
                  <.tag text={@tag} />
                </div>
              <% end %>
            </div>
          </div>
          <div class="flex-grow" />
          <div>
            <Button.dynamic_bar buttons={@buttons} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:number, :integer, required: true)
  attr(:active, :boolean, default: false)
  attr(:target, :any, required: true)
  attr(:buttons, :list, required: true)

  def page_list_item(assigns) do
    ~H"""
    <div
      class={"p-4 rounded-lg border cursor-pointer #{if @active do "bg-grey6 border-grey4" else "hover:bg-grey6 border-white" end} "}
      phx-click="select_page"
      phx-value-item={@id}
      phx-target={@target}
    >
      <div class="flex flex-row gap-6">
        <.number_icon number={@number} active={@active} />
        <div class="mt-[2px]">
          <Text.title6 margin=""><%= @title %></Text.title6>
        </div>
        <div class="flex-grow" />
        <div>
          <Button.dynamic_bar buttons={@buttons} />
        </div>
      </div>
    </div>
    """
  end
end
