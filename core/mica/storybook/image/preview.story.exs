defmodule Storybook.Frameworks.Pixel.Image.Preview do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Image.preview/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{placeholder: "/images/icons/placeholder_square.svg", image_url: nil},
        slots: []
      }
    ]
  end
end
