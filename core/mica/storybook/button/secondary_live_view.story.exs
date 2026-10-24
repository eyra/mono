defmodule Storybook.Frameworks.Pixel.Button.SecondaryLiveView do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.secondary_live_view/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Delete", event: "delete", target: nil},
        slots: []
      }
    ]
  end
end
