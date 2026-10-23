defmodule Storybook.Frameworks.Pixel.Widget.Number do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Widget.number/1

  # The component renders `metric`; the declared `integer` attr is unused.
  def variations do
    [
      %Variation{
        id: :primary,
        attributes: %{integer: 128, metric: 128, label: "Started participants"}
      },
      %Variation{
        id: :positive,
        attributes: %{integer: 96, metric: 96, label: "Finished participants", color: :positive}
      },
      %Variation{
        id: :target_up_not_reached,
        attributes: %{
          integer: 96,
          metric: 96,
          label: "Finished of 150 target",
          target: 150,
          target_direction: :up
        }
      },
      %Variation{
        id: :target_down_exceeded,
        attributes: %{
          integer: 12,
          metric: 12,
          label: "Declined participants",
          target: 5,
          target_direction: :down
        }
      }
    ]
  end
end
