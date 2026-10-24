defmodule Storybook.Frameworks.Pixel.Button.Face.Icon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{icon: :edit, alt: "Edit"},
        slots: []
      }
    ]
  end
end
