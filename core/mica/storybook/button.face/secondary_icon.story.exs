defmodule Storybook.Frameworks.Pixel.Button.Face.SecondaryIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.secondary_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Add page", icon: :add},
        slots: []
      }
    ]
  end
end
