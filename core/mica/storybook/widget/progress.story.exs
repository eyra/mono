defmodule Storybook.Frameworks.Pixel.Widget.Progress do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Widget.progress/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          label: "Participants",
          pending_amount: 18,
          target_amount: 150,
          done_amount: 96,
          done_label: "Finished",
          pending_label: "Started",
          target_label: "Open"
        },
        slots: []
      }
    ]
  end
end
