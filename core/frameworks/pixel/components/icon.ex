defmodule Frameworks.Pixel.Icon do
  use CoreWeb, :html

  attr(:type, :atom, required: true)
  attr(:src, :any, required: true)
  attr(:size, :string, required: true)
  attr(:border_size, :string, default: "border-0")
  attr(:border_radius, :string, default: "rounded-none")
  attr(:bg_color, :string, default: "")

  def generic(%{size: size} = assigns) do
    style =
      case size do
        "L" -> "w-12 h-12 sm:h-16 sm:w-16 lg:h-84px lg:w-84px"
        "S" -> "h-14 w-14"
        _ -> "h-6 w-6"
      end

    assigns = assign(assigns, :style, style)

    ~H"""
    <div class={"border-grey4/100 #{@size} #{@bg_color} #{@border_size} #{@border_radius}"}>
      <.generic_body {assigns}/>
    </div>
    """
  end

  attr(:src, :any, required: true)
  attr(:size, :string, required: true)
  attr(:border_radius, :string, default: "rounded-none")

  def generic_body(%{type: :url} = assigns) do
    ~H"""
    <img class={"w-full h-full #{@border_radius}"} src={@src} alt="">
    """
  end

  def generic_body(%{type: :static} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center">
      <img src={"/images/icons/#{@src}.svg"} alt={@src}>
    </div>
    """
  end

  def generic_body(%{type: :emoji, size: size} = assigns) do
    style =
      case size do
        "L" -> "text-title1 font-title1 text-grey1"
        "M" -> "text-title2 font-title2 text-grey1"
        "S" -> "text-title3 font-title3 text-grey1"
      end

    assigns = assign(assigns, :style, style)

    ~H"""
    <div class={"w-full h-full #{@border_radius} #{@style}"}><%= @src %></div>
    """
  end

  attr(:url, :string, required: true)

  def card(assigns) do
    ~H"""
    <.generic
      src={@url}
      size="h-14 w-14"
      type={:url}
      bg_color="bg-white"
      border_size="border-2"
      border_radius="rounded-full"
    />
    """
  end

  attr(:type, :atom, required: true)
  attr(:src, :any, required: true)
  attr(:size, :string, default: "L")

  def square(assigns) do
    ~H"""
    <.generic {assigns} />
    """
  end

  attr(:url, :string, required: true)

  def hero(assigns) do
    ~H"""
    <Icon.generic
      src={@url}
      size="w-12 h-12 sm:h-16 sm:w-16 lg:h-84px lg:w-84px"
      type={:url}
      border_size="border-2"
      bg_color="bg-white"
      border_radius="rounded-full"
    />
    """
  end

  attr(:name, :any, required: true)
  attr(:size, :atom, required: true)

  def menu_home(%{name: name, size: size} = assigns) do
    icon_name =
      case size do
        :narrow -> "#{name}_narrow"
        :wide -> "#{name}_wide"
        _ -> "#{name}"
      end

    assigns = assign(assigns, :icon_name, icon_name)

    ~H"""
    <Icon.generic
      type={:static}
      src={@icon_name}
      size="h-8 sm:h-12"
    />
    """
  end

  attr(:name, :any, required: true)
  attr(:active?, :any, required: true)

  def menu_item(%{name: name, active?: active?} = assigns) do
    icon_name =
      if active? do
        "#{name}_active"
      else
        name
      end

    assigns = assign(assigns, :icon_name, icon_name)

    ~H"""
    <Icon.generic
      type={:static}
      src={@icon_name}
      size="XS"
    />
    """
  end
end
