defmodule Storybook.Frameworks.Pixel.Hero.Dynamic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.dynamic/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{type: nil, params: %{}},
        slots: []
      }
    ]
  end
end
