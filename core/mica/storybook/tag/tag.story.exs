defmodule Storybook.Frameworks.Pixel.Tag.Tag do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tag.tag/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{text: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
