defmodule Storybook.Frameworks.Pixel.InlineBlock.InlineBlock do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.InlineBlock.inline_block/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{description: "Lorem ipsum", title: "Lorem ipsum"},
        slots: ["Lorem ipsum"]
      }
    ]
  end
end
