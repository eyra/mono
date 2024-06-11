defmodule Frameworks.Pixel.Tag do
  @moduledoc """
  A colored button with white text
  """
  use CoreWeb, :pixel

  attr(:text, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-primary")
  attr(:bg_opacity, :string, default: "bg-opacity-20")

  def tag(assigns) do
    ~H"""
    <div class="h-8 bg-white rounded">
      <div class={"flex flex-col justify-center h-full rounded items-center #{@bg_color} #{@bg_opacity}"}>
        <div class={"text-label font-label ml-3 mr-3 #{@text_color}"}>
          <%= @text %>
        </div>
      </div>
    </div>
    """
  end
end
