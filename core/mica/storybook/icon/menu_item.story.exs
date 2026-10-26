defmodule Storybook.Frameworks.Pixel.Icon.MenuItem do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Icon.menu_item/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{name: :projects, active?: false},
        slots: []
      }
    ]
  end
end
