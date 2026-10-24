defmodule Storybook.Frameworks.Pixel.ImagePreview.ImagePreview do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ImagePreview.image_preview/1

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
