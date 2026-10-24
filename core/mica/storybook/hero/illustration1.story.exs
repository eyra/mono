defmodule Storybook.Frameworks.Pixel.Hero.Illustration1 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.illustration1/1

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
