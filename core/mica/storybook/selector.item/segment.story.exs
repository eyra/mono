defmodule Storybook.Frameworks.Pixel.Selector.Item.Segment do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Selector.Item.segment/1

  def variations do
    [
      %Variation{
        id: :unselected,
        description: "Unselected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: false}}
      },
      %Variation{
        id: :selected,
        description: "Selected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: true}}
      }
    ]
  end
end
