defmodule Storybook.Frameworks.Pixel.Button.PrimaryLiveView do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.primary_live_view/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Save", event: "save"},
        slots: []
      }
    ]
  end
end
