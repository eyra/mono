defmodule Storybook.Frameworks.Pixel.Button.Face.LabelIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.label_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Edit", icon: :edit},
        slots: []
      }
    ]
  end
end
