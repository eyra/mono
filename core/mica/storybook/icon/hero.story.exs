defmodule Storybook.Frameworks.Pixel.Icon.Hero do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Icon.hero/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{url: "/images/icons/placeholder_square.svg"},
        slots: []
      }
    ]
  end
end
