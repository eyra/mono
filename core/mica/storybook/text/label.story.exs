defmodule Storybook.Frameworks.Pixel.Text.Label do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.label/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Duration"]
      }
    ]
  end
end
