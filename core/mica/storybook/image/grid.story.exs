defmodule Storybook.Frameworks.Pixel.Image.Grid do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Image.grid/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "image-1",
          index: "1",
          url: "/images/illustrations/cards.svg",
          srcset: "/images/illustrations/cards.svg 1x",
          selected: true
        },
        slots: []
      }
    ]
  end
end
