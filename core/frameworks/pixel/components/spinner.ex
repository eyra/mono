defmodule Frameworks.Pixel.Spinner do
  use CoreWeb, :html

  attr(:alt, :string, default: "Loading")
  attr(:size, :string, default: "")
  attr(:color, :string, default: "primary")

  def static(assigns) do
    size = Map.get(assigns, :size, "")
    color = Map.get(assigns, :color, "primary")

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

    assigns =
      assign(assigns,
        size_class: size_class,
        color_class: color_class,
        image_path: spinner_asset_path(color)
      )

    ~H"""
      <div class={"prism-spinner #{@size_class} #{@color_class}"}>
        <img src={@image_path} alt={@alt}>
      </div>
    """
  end

  defp spinner_asset_path("delete"), do: "/images/icons/spinner_static_delete@3x.png"
  defp spinner_asset_path(color), do: "/images/icons/spinner_static_#{color}@3x.png"
end
