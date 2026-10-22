defmodule Frameworks.Pixel.Spinner do
  use CoreWeb, :html

  attr(:alt, :string, default: "Loading")
  attr(:size, :string, default: "")
  attr(:color, :string, default: nil)

  def static(assigns) do
    size = Map.get(assigns, :size, "")
    color = Map.get(assigns, :color)

    size_class =
      case size do
        "w-4 h-4" -> "prism-spinner-sm"
        "w-8 h-8" -> "prism-spinner-lg"
        _ -> ""
      end

    color_class = if color, do: "text-#{color}", else: ""
    assigns = assign(assigns, size_class: size_class, color_class: color_class)

    ~H"""
    <span
      class={"prism-spinner #{@size_class} #{@color_class}"}
      role="status"
      aria-label={@alt}
    ></span>
    """
  end
end
