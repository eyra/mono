defmodule Frameworks.Pixel.Card.Highlight do
  @moduledoc """
   Flag-like label used on a card to highlight specific state
  """
  use Surface.Component

  alias Frameworks.Pixel.Text.Title5

  prop(title, :string, required: true)
  prop(text, :string, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex items-center justify-center">
      <div class="text-center ml-6 mr-6">
        <div class="mt-6 mb-7 sm:mt-8 sm:mb-9">
          <Title5 color="text-primary">{@title}</Title5>
          <div class="mb-1 sm:mb-2" />
          <Title5>{@text}</Title5>
        </div>
      </div>
    </div>
    """
  end
end
