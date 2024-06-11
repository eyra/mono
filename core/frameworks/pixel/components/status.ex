defmodule Frameworks.Pixel.Status do
  @moduledoc """
  A colored button with white text
  """
  use CoreWeb, :pixel

  attr(:text, :string, required: true)
  attr(:bg_color, :string, required: true)
  attr(:text_color, :string, required: true)
  attr(:bg_opacity, :string, required: true)

  def generic(assigns) do
    ~H"""
    <div class="flex h-10">
      <div>
        <div class={"flex flex-col justify-center h-full items-center rounded #{@bg_color} #{@bg_opacity}"}>
          <div class={"text-label font-label ml-4 mr-4 #{@text_color}"}>
            {@text}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:text, :string, required: true)

  def info(assigns) do
    ~H"""
    <.generic
      text={@text}
      text_color="text-success"
      bg_color="bg-successlight"
      bg_opacity="bg-opacity-100"
    />
    """
  end

  attr(:text, :string, required: true)

  def warning(assigns) do
    ~H"""
    <.generic
      text={@text}
      text_color="text-warning"
      bg_color="bg-warninglight"
      bg_opacity="bg-opacity-100"
    />
    """
  end

  attr(:text, :string, required: true)

  def error(assigns) do
    ~H"""
    <.generic
      text={@text}
      text_color="text-delete"
      bg_color="bg-deletelight"
      bg_opacity="bg-opacity-100"
    />
    """
  end
end
