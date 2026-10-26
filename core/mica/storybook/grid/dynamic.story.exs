defmodule Storybook.Frameworks.Pixel.Grid.Dynamic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Grid.dynamic/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Lorem ipsum"]
      }
    ]
  end
end
