defmodule Storybook.Frameworks.Pixel.Logo.MenuHome do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Logo.menu_home/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{name: nil, size: :default},
        slots: []
      }
    ]
  end
end
