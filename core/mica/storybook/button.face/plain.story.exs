defmodule Storybook.Frameworks.Pixel.Button.Face.Plain do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.plain/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Skip for now"},
        slots: []
      }
    ]
  end
end
