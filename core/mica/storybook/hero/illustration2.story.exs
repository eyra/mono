defmodule Storybook.Frameworks.Pixel.Hero.Illustration2 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.illustration2/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
