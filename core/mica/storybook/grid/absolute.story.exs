defmodule Storybook.Frameworks.Pixel.Grid.Absolute do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Grid.absolute/1

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
