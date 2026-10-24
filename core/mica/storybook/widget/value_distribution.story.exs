defmodule Storybook.Frameworks.Pixel.Widget.ValueDistribution do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Widget.value_distribution/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          label: "Credits per student",
          values: [0, 1, 2, 2, 3, 3, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 12, 14],
          scale: 2
        }
      }
    ]
  end
end
