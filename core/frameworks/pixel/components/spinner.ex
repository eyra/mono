defmodule Frameworks.Pixel.Spinner do
  use CoreWeb, :html

  attr(:alt, :string, default: "Loading")
  attr(:size, :string, default: "w-6 h-6")
  attr(:color, :string, default: "primary")

  def static(assigns) do
    ~H"""
      <div class={"#{@size} animate-spin"}>
        <img src={"/images/icons/spinner_static_#{@color}@3x.png"} alt={@alt}>
      </div>
    """
  end
end
