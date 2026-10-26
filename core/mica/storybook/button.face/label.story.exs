defmodule Storybook.Frameworks.Pixel.Button.Face.Label do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.label/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Cancel"},
        slots: []
      }
    ]
  end
end
