defmodule Systems.Manual.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.NumberIcon
  import Frameworks.Pixel.Line
  import Frameworks.Pixel.Toolbar
  import Frameworks.Pixel.Image, only: [blurhash: 1]

  attr(:items, :list, required: true)
  attr(:selected_chapter_id, :integer, default: nil)
  attr(:target, :any, required: true)

  def chapter_list(assigns) do
    ~H"""
    <div class="flex flex-col sm:gap-2">
      <%= for item <- @items do %>
        <.chapter_list_item {item} selected={@selected_chapter_id == item.id} target={@target} />
      <% end %>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:selected, :boolean, default: false)
  attr(:target, :any, required: true)
  attr(:number, :integer, required: true)

  def chapter_list_item(assigns) do
    ~H"""
    <div
      class={"touchstart-sensitive p-4 rounded-lg border cursor-pointer #{if @selected do "bg-grey6 border-grey4" else "active:bg-grey6 hover:bg-grey6 border-white" end} "}
      phx-click="select_chapter"
      phx-value-item={@id}
      phx-target={@target}
    >
      <div class="flex flex-col gap-4">
        <div class="flex flex-row gap-4">
          <div class="flex flex-row gap-4">
            <.number_icon number={@number} active={true} />
            <div class="flex flex-col gap-2">
              <div class="mt-[3px] sm:mt-[1px]">
                <Text.title5 align="text-left"><%= @title %></Text.title5>
              </div>
            </div>
          </div>
          <div class="flex-grow md:flex-none" />
          <%= if @tag do %>
            <div class="flex flex-row">
                <.tag text={@tag} />
            </div>
        <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:pages, :list, required: true)
  attr(:selected_page, :map, required: true)
  attr(:back_button, :map, required: true)
  attr(:left_button, :map, default: nil)
  attr(:right_button, :map, default: nil)
  attr(:fullscreen_button, :map, default: nil)
  attr(:select_page_event, :string, required: true)
  attr(:select_page_target, :any, required: true)

  def chapter_desktop(assigns) do
    ~H"""
    <div id={"manual-desktop-chapter-#{@id}-page-#{@selected_page.id}"} phx-hook="ResetScroll" class="w-full h-full flex flex-col gap-8">
      <div class="flex-1 w-full h-full flex flex-row gap-6">
        <!-- Master View -->
        <div class="flex-shrink-0 w-[296px] h-full">
          <div class="flex flex-col gap-8">
            <div class="flex flex-col gap-4">
              <div class="flex gap-x-4 gap-y-2">
                <Text.title7 color="text-grey2"><%= @title %></Text.title7>
                <div class="flex-grow" />
                <%= if @label do %>
                  <.tag text={@label} />
                <% end %>
              </div>
              <.line />
            </div>
            <.page_list items={@pages} selected_page={@selected_page} select_page_event={@select_page_event} select_page_target={@select_page_target} />
          </div>
        </div>
        <!-- Detail View -->
        <div class="flex-grow h-full flex flex-col gap-8 mb-8">
          <.page id={"desktop-page-#{@id}"} page={@selected_page} fullscreen_button={@fullscreen_button} padding="pb-4" />
        </div>
      </div>
      <div class="absolute bottom-0 left-0 right-0 bg-white">
        <.toolbar back_button={@back_button} left_button={@left_button} right_button={@right_button} />
      </div>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:indicator, :string, default: nil)
  attr(:selected_page, :map, required: true)
  attr(:back_button, :map, required: true)
  attr(:left_button, :map, default: nil)
  attr(:right_button, :map, default: nil)
  attr(:fullscreen_button, :map, default: nil)

  def chapter_mobile(assigns) do
    ~H"""
    <div id={"manual-mobile-chapter-#{@id}-page-#{@selected_page.id}"} phx-hook="ResetScroll" class="w-full h-full">
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-4">
          <div class="flex gap-x-4 gap-y-2">
            <Text.title7 color="text-grey2"><%= @title %></Text.title7>
            <div class="flex-grow" />
            <%= if @label do %>
              <.tag text={@label} />
            <% end %>
          </div>
        </div>
        <.page id={"mobile-page-#{@selected_page.id}"} page={@selected_page} indicator={@indicator} fullscreen_button={@fullscreen_button} padding="pb-4" />
      </div>
      <div class="absolute bottom-0 left-0 right-0 bg-white">
        <.toolbar back_button={@back_button} left_button={@left_button} right_button={@right_button} />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:page, :map, required: true)
  attr(:indicator, :string, default: nil)
  attr(:fullscreen_button, :map, default: nil)
  attr(:padding, :string, default: "")

  def page(assigns) do
    ~H"""
    <div class={"flex flex-col gap-4 sm-gap-8 #{@padding}"}>
      <div class="font-title5 text-title5 sm:font-title2 sm:text-title2">
        <%= if @indicator do %>
          <span class="text-primary"><%= @indicator %> </span>
        <% end %>
        <%= @page.title %>
      </div>
      <%= if @page.image_info do %>
        <div id={"#{@id}-image-container"} phx-hook="FullscreenImage" class="flex w-full flex-col gap-4">
          <%= if Map.get(@page.image_info, :blur_hash) do %>
            <.blurhash
              id={"#{@id}-image"}
              image={@page.image_info}
              style="dynamic"
            />
          <% else %>
            <img src={@page.image_info.url} />
          <% end %>
          <%= if @fullscreen_button do %>
            <Button.dynamic {@fullscreen_button} />
          <% end %>
        </div>
      <% end %>
      <div class="wysiwyg">
        <%= raw @page.text %>
      </div>
    </div>
    """
  end

  attr(:items, :list, required: true)
  attr(:selected_page, :map, required: true)
  attr(:select_page_event, :string, required: true)
  attr(:select_page_target, :any, required: true)

  def page_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <%= for item <- @items do %>
        <.page_list_item {item} selected={@selected_page.id == item.id} select_page_event={@select_page_event} select_page_target={@select_page_target} />
      <% end %>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)
  attr(:selected, :boolean, default: false)
  attr(:target, :any, required: true)
  attr(:number, :integer, required: true)
  attr(:select_page_event, :string, required: true)
  attr(:select_page_target, :any, required: true)

  def page_list_item(assigns) do
    ~H"""
    <div
      class={"touchstart-sensitive p-4 rounded-lg border cursor-pointer #{if @selected do "bg-grey6 border-grey4" else "hover:bg-grey6 border-white" end} "}
      phx-click={@select_page_event}
      phx-value-item={@id}
      phx-target={@select_page_target}
    >
      <div class="flex flex-col gap-4">
        <div class="flex flex-row gap-4">
          <div class="flex flex-row gap-4">
            <.number_icon number={@number} active={@selected} />
            <div class="flex flex-col gap-2">
              <div class="mt-[2px]">
                <Text.title6 margin="" align="text-left"><%= @title %></Text.title6>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
