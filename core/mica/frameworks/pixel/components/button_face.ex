defmodule Frameworks.Pixel.Button.Face do
  @moduledoc """
  The look of a button, inside a `Frameworks.Pixel.Button.Action`. Every face but
  the menu faces renders Prism's button (`Frameworks.Pixel.button/1`) as a
  `<div>`, since the action is the clickable element.

  `bg_color`, `text_color`, `border_color` and `font` take Tailwind classes that
  override Prism's look; without them a face has its Prism variant's colors and
  typography.

  Prism's button is inline (`inline-flex`); the icon, label and `*_icon` faces take
  a line of their own (`flex`), so no line box adds height around them.
  """
  use MicaWeb, :pixel

  alias Frameworks.Pixel
  alias Frameworks.Pixel.Icon
  alias Frameworks.Pixel.Logo

  attr(:text, :string, required: true)
  attr(:font, :string, default: nil)

  def link(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:link} class={@font}><%= @text %></Pixel.button>
    """
  end

  def icon_name(%{icon: icon, color: nil}), do: "#{icon}.svg"
  def icon_name(%{icon: icon, color: color}), do: "#{icon}_#{color}.svg"
  def icon_name(%{icon: icon}), do: "#{icon}.svg"

  attr(:icon, :atom, required: true)
  attr(:color, :string, default: nil)
  attr(:alt, :string, default: "")
  attr(:size, :string, default: nil)

  def icon(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:icon} class={["flex", @size]}>
      <:icon><img src={~p"/images/icons/#{icon_name(assigns)}"} alt={@alt}></:icon>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:color, :string, default: nil)
  attr(:text_color, :string, default: nil)
  attr(:height, :string, default: "h-10")

  def label_icon(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:plain} padded={false} class={["flex w-fit font-label text-label", @height, @text_color]}>
      <%= @label %>
      <:icon><img src={~p"/images/icons/#{icon_name(assigns)}"} alt={@label}></:icon>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:wrap, :boolean, default: false)
  attr(:text_color, :string, default: nil)
  attr(:font, :string, default: nil)

  def label(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:text} padded={not @wrap} class={["flex w-fit", @font, @text_color]}>
      <%= @label %>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, default: :forward)
  attr(:icon_align, :atom, default: :right)
  attr(:text_color, :string, default: nil)

  def plain_icon(assigns) do
    ~H"""
    <Pixel.button
      as="div"
      variant={:plain}
      padded={false}
      icon_position={if @icon_align == :right, do: :end, else: :start}
      class={["flex w-fit", @text_color]}
    >
      <%= @label %>
      <:icon><img src={~p"/images/icons/#{"#{@icon}.svg"}"} alt={@label}></:icon>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:text_color, :string, default: nil)

  def plain(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:plain} padded={false} class={["w-full", @text_color]}>
      <span class="whitespace-pre-wrap"><%= @label %></span>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:bg_color, :string, default: nil)
  attr(:text_color, :string, default: nil)

  def primary_icon(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:primary} class={["flex w-full h-12", @bg_color, @text_color]}>
      <%= @label %>
      <:icon><img src={~p"/images/icons/#{"#{@icon}.svg"}"} alt={@label}></:icon>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:bg_color, :string, default: nil)
  attr(:text_color, :string, default: nil)
  attr(:loading, :boolean, default: false)
  attr(:full_width, :boolean, default: false)

  def primary(assigns) do
    ~H"""
    <Pixel.button
      as="div"
      variant={:primary}
      loading={@loading}
      class={[@full_width && "w-full", @bg_color, @text_color]}
    >
      <%= @label %>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:border_color, :string, default: nil)
  attr(:text_color, :string, default: nil)
  attr(:loading, :boolean, default: false)

  def secondary(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:secondary} loading={@loading} class={[@border_color, @text_color]}>
      <%= @label %>
    </Pixel.button>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:border_color, :string, default: nil)
  attr(:text_color, :string, default: nil)

  def secondary_icon(assigns) do
    ~H"""
    <Pixel.button as="div" variant={:secondary} class={["flex", @border_color, @text_color]}>
      <%= @label %>
      <:icon><img src={~p"/images/icons/#{"#{@icon}.svg"}"} alt={@label}></:icon>
    </Pixel.button>
    """
  end

  attr(:icon, :atom, required: true)
  attr(:size, :atom, default: :wide)

  def menu_home(assigns) do
    ~H"""
      <div class={"flex flex-row items-center justify-start rounded-full focus:outline-none h-12"}>
        <div class="flex flex-col items-center justify-center">
          <Logo.menu_home name={@icon} size={@size} />
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
              <div class={"w-5 h-5 flex items-center justify-center rounded-full #{@counter_color}"}>
                <div class="text-captionsmall font-caption text-white">
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
