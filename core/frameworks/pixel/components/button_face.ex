defmodule Frameworks.Pixel.Button.Face do
  use CoreWeb, :html

  alias Frameworks.Pixel.Icon

  attr(:text, :string, required: true)
  attr(:font, :string, default: "text-link font-link")

  def link(assigns) do
    ~H"""
    <div class="text-primary underline cursor-pointer zfocus:outline-none">
      <%= @text %>
    </div>
    """
  end

  def icon_name(%{icon: icon, color: nil}), do: "#{icon}"
  def icon_name(%{icon: icon, color: color}), do: "#{icon}_#{color}"
  def icon_name(%{icon: icon}), do: "#{icon}"

  attr(:icon, :atom, required: true)
  attr(:color, :string, default: nil)
  attr(:alt, :string, default: "")
  attr(:size, :string, default: "h-6 w-6")

  def icon(assigns) do
    ~H"""
    <div class={"active:opacity-80 cursor-pointer #{@size}"}>
      <img src={"/images/icons/#{icon_name(assigns)}.svg"} alt={@alt}>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:text_color, :string, default: "text-grey1")

  def label_icon(assigns) do
    ~H"""
    <div class="pt-0 pb-1px active:pt-1px active:pb-0 font-button text-button rounded bg-opacity-0">
      <div class="flex justify-left items-center w-full">
        <div>
          <img class="mr-3 -mt-2px" src={"/images/icons/#{@icon}.svg"} alt={@label}>
        </div>
        <div class="h-10">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"text-label font-label #{@text_color}"}>
              <%= @label %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def padding(%{wrap: true}), do: "pt-1px pb-1px active:pt-2px active:pb-0"
  def padding(_), do: "pt-13px pb-13px active:pt-14px active:pb-3 pr-4 pl-4"

  attr(:label, :string, required: true)
  attr(:wrap, :boolean, default: false)
  attr(:text_color, :string, default: "text-primary")
  attr(:font, :string, default: "font-button text-button")

  def label(assigns) do
    ~H"""
    <div class={"rounded bg-opacity-0 #{@font} #{padding(assigns)} #{@text_color}"}>
      <%= @label %>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, default: :forward)
  attr(:text_color, :string, default: "text-grey1")

  def plain_icon(assigns) do
    ~H"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"flex-wrap text-button font-button #{@text_color}"}>
              <%= @label %>
            </div>
          </div>
        </div>
        <div>
          <img class="ml-4 -mt-2px" src={"/images/icons/#{@icon}.svg"} alt={@label}>
        </div>
      </div>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:text_color, :string, default: "text-grey1")

  def plain(assigns) do
    ~H"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"flex-wrap text-button font-button #{@text_color}"}>
              <span class="whitespace-pre-wrap"><%= @label %></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-white")

  def primary_icon(assigns) do
    ~H"""
    <div class={"pt-1 pb-1 active:pt-5px active:pb-3px active:shadow-top4px w-full rounded pl-4 pr-4 #{@bg_color}"}>
      <div class="flex justify-center items-center w-full">
        <div>
          <img class="mr-3 -mt-1" src={"/images/icons/#{@icon}.svg"} alt={@label}>
        </div>
        <div class="h-10">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"text-button font-button #{@text_color}"}>
              <%= @label %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-white")

  def primary(assigns) do
    ~H"""
    <div class={"pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 #{@bg_color} #{@text_color}"}>
      <%= @label %>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:border_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-primary")

  def secondary(assigns) do
    ~H"""
    <div class={"pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button rounded bg-opacity-0 pr-4 pl-4 #{@border_color} #{@text_color}"}>
      <%= @label %>
    </div>
    """
  end

  attr(:icon, :atom, required: true)
  attr(:size, :atom, default: :wide)

  def menu_home(assigns) do
    ~H"""
      <div class={"flex flex-row items-center justify-start rounded-full focus:outline-none h-12"}>
        <div class="flex flex-col items-center justify-center">
          <Icon.menu_home name={@icon} size={@size} />
        </div>
      </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:active?, :boolean, default: false)
  attr(:counter, :integer, required: true)
  attr(:icon, :map, default: nil)
  attr(:text_color, :string, default: "text-grey1")

  def menu_item(%{counter: counter, active?: active?, title: title} = assigns) do
    counter_color =
      case counter do
        0 -> "bg-success"
        _ -> "bg-secondary"
      end

    bg_color =
      if active? and not is_nil(title) do
        "bg-grey4"
      else
        ""
      end

    hover =
      if is_nil(title) do
        ""
      else
        "hover:bg-grey4 px-4"
      end

    assigns =
      assign(assigns, %{
        counter_color: counter_color,
        bg_color: bg_color,
        hover: hover
      })

    ~H"""
      <div class={"flex flex-row items-center justify-start rounded-full focus:outline-none h-10 gap-3 #{@bg_color} #{@hover}"}>
        <%= if @icon do %>
          <div class="flex flex-col items-center justify-center">
            <Icon.menu_item name={@icon} active?={@active?} />
          </div>
        <% end %>
        <%= if @title do %>
          <div>
            <div class="flex flex-col items-center justify-center">
              <div class={"text-button font-button #{@text_color} mt-1px"}>
                <%= @title %>
              </div>
            </div>
          </div>
        <% end %>
        <%= if @counter do %>
          <div class="flex-grow" />
          <div>
            <div class="flex flex-col items-center justify-center">
              <div class={"px-6px rounded-full #{@counter_color}"}>
                <div class="text-captionsmall font-caption text-white mt-2px">
                  <%= @counter %>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    """
  end
end
