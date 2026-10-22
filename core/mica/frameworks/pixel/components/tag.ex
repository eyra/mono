defmodule Frameworks.Pixel.Tag do
  @moduledoc """
  A colored tag/badge component.
  """
  use CoreWeb, :pixel

  attr(:text, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-primary")
  attr(:bg_opacity, :string, default: "bg-opacity-20")

  def tag(assigns) do
    ~H"""
    <span class="prism-tag">
      <span class={"prism-tag-inner #{@bg_color} #{@bg_opacity} #{@text_color}"}>
        <%= @text %>
      </span>
    </span>
    """
  end
end
