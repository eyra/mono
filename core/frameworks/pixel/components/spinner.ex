defmodule Frameworks.Pixel.Spinner do
  use CoreWeb, :html

  attr(:alt, :string, default: "Loading")
  attr(:size, :string, default: "")
  attr(:color, :string, default: "primary")

  def static(%{size: size, color: color} = assigns) do
    size_class =
      case size do
        "w-4 h-4" -> "prism-spinner-sm"
        "w-8 h-8" -> "prism-spinner-lg"
        _ -> ""
      end

    color_class =
      case color do
        "white" -> "prism-spinner-white"
        "primary" -> "prism-spinner-primary"
        _ -> ""
      end

    assigns = assign(assigns, size_class: size_class, color_class: color_class)

    ~H"""
      <div class={"prism-spinner #{@size_class} #{@color_class}"}>
        <img src={"/images/icons/spinner_static_#{@color}@3x.png"} alt={@alt}>
      </div>
    """
  end
end
