defmodule Storybook.Frameworks.Pixel.Widget.ValueDistributionBar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Widget.value_distribution_bar/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{height: 0.6, value_count: 12, range_label: "4 - 5"},
        slots: []
      }
    ]
  end
end
