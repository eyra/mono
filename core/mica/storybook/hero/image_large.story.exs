defmodule Storybook.Frameworks.Pixel.Hero.ImageLarge do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.image_large/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Lorem ipsum", image_info: nil, subtitle: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
