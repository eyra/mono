defmodule Systems.Manual.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.NumberIcon
  import Frameworks.Pixel.Line

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
      id={"manual-chapter-list-item-#{@id}"}
      class={"p-4 rounded-lg border cursor-pointer #{if @selected do "bg-grey6 border-grey4" else "active:bg-grey6 hover:bg-grey6 border-white" end} "}
      phx-click="select_chapter"
      phx-value-item={@id}
      phx-target={@target}
      phx-hook="ButtonTouchDevice"
    >
      <div class="flex flex-col gap-4">
        <div class="flex flex-row gap-4">
          <div class="flex flex-row gap-4">
            <.number_icon number={@number} active={@selected} />
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
  attr(:next_button, :map, required: true)
  attr(:previous_button, :map, required: true)
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
              <div class="flex flex-wrap gap-x-4 gap-y-2 items-center">
                <Text.title7 color="text-grey2"><%= @title %></Text.title7>
                <%= if @label do %>
                  <.tag text={@label} />
                <% end %>
              </div>
              <.line />
            </div>
            <.page_list items={@pages} selected_page={@selected_page} select_page_event={@select_page_event} select_page_target={@select_page_target} />
            <div class="flex flex-col gap-4">
              <.line />
              <Button.dynamic {@back_button} />
            </div>
          </div>
        </div>
        <!-- Detail View -->
        <div class="flex-grow h-full flex flex-col gap-8 mb-8">
          <.page id={"desktop-page-#{@id}"} page={@selected_page} fullscreen_button={@fullscreen_button} />
          <.line />
          <div class="flex-shrink-0 flex flex-row gap-4 items-center">
            <%= if @previous_button do %>
              <Button.dynamic {@previous_button} />
            <% end %>
            <div class="flex-grow" />
            <%= if @next_button do %>
              <Button.dynamic {@next_button} />
            <% end %>
          </div>
        </div>
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
  attr(:next_button, :map, default: nil)
  attr(:previous_button, :map, default: nil)
  attr(:fullscreen_button, :map, default: nil)

  def chapter_mobile(assigns) do
    ~H"""
    <div id={"manual-mobile-chapter-#{@id}-page-#{@selected_page.id}"} phx-hook="ResetScroll" class="w-full h-full">
      <div class="flex flex-col gap-8">
        <div class="flex flex-col gap-4">
          <div class="flex flex-wrap gap-x-4 gap-y-2 items-center">
            <Text.title7 color="text-grey2"><%= @title %></Text.title7>
            <%= if @label do %>
              <.tag text={@label} />
            <% end %>
          </div>
          <.line />
        </div>
        <.page id={"mobile-page-#{@id}"} page={@selected_page} indicator={@indicator} fullscreen_button={@fullscreen_button} padding="pb-[98px]" />
      </div>
      <div class="absolute bottom-0 left-0 right-0 px-4 sm:px-8 h-[80px] bg-white">
        <div class="flex flex-col gap-4 h-full">
          <.line />
          <div class="flex-shrink-0 h-12 flex flex-row gap-4 items-center">
            <%= if @previous_button do %>
              <Button.dynamic {@previous_button} />
            <% else %>
              <Button.dynamic {@back_button} />
            <% end %>
            <div class="flex-grow" />
            <%= if @next_button do %>
              <Button.dynamic {@next_button} />
            <% else %>
              <%= if @previous_button do %>
                <Button.dynamic {@back_button} />
              <% end %>
            <% end %>
          </div>
        </div>
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
    <div class={"flex flex-col gap-8 #{@padding}"}>
      <div class="font-title5 text-title5 sm:font-title2 sm:text-title2">
        <%= if @indicator do %>
          <span class="text-primary"><%= @indicator %> </span>
        <% end %>
        <%= @page.title %>
      </div>
      <%= if @page.image do %>
        <div id={"manual-page-#{@id}-image"} phx-hook="FullscreenImage" class="flex flex-col gap-4">
          <img src={@page.image} />
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
      class={"p-4 rounded-lg border cursor-pointer #{if @selected do "bg-grey6 border-grey4" else "hover:bg-grey6 border-white" end} "}
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
