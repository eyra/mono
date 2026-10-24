defmodule Storybook.Frameworks.Pixel.Grid.Image do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Grid.image/1

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
