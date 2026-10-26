defmodule Storybook.Frameworks.Pixel.Button.Face.Primary do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.primary/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Publish"},
        slots: []
      }
    ]
  end
end
