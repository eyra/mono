defmodule Storybook.Frameworks.Pixel.Block.Block do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Block.block/1

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
