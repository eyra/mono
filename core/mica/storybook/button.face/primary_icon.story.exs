defmodule Storybook.Frameworks.Pixel.Button.Face.PrimaryIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.primary_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Export", icon: :export},
        slots: []
      }
    ]
  end
end
