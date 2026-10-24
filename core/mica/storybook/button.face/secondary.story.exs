defmodule Storybook.Frameworks.Pixel.Button.Face.Secondary do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.secondary/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Decline"},
        slots: []
      }
    ]
  end
end
