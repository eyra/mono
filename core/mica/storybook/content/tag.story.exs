defmodule Storybook.Frameworks.Pixel.Content.Tag do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Content.tag/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{type: nil, text: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
