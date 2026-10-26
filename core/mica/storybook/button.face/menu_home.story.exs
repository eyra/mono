defmodule Storybook.Frameworks.Pixel.Button.Face.MenuHome do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.menu_home/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{icon: :next},
        slots: []
      }
    ]
  end
end
