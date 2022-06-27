defmodule Frameworks.Pixel.Card.Label do
  @moduledoc """
   Flag-like label used on a card to highlight specific state
  """
  use Surface.Component

  alias Frameworks.Pixel.Text.Title5

  prop(path_provider, :any, required: true)
  prop(text, :string, required: true)
  prop(type, :atom, default: :primary)

  def bg_color(:delete), do: "bg-delete"
  def bg_color(:warning), do: "bg-warning"
  def bg_color(:success), do: "bg-success"
  def bg_color(:primary), do: "bg-primary"
  def bg_color(:secondary), do: "bg-secondary"
  def bg_color(:tertiary), do: "bg-tertiary"
  def bg_color(:disabled), do: "bg-grey5"
  def bg_color(type), do: "bg-#{type}"

  def text_color(:tertiary), do: "text-grey1"
  def text_color(:disabled), do: "text-grey1"
  def text_color(_), do: "text-white"

  def render(assigns) do
    ~F"""
    <div class="flex">
      <div class={"h-14 pl-4 pr-2 #{bg_color(@type)}"}>
        <div class="flex flex-row justify-center h-full items-center">
          <Title5 color={text_color(@type)}>{@text}</Title5>
        </div>
      </div>
      <img src={@path_provider.static_path("/images/label-arrow-#{@type}.svg")} alt={@text}>
    </div>
    """
  end
end
