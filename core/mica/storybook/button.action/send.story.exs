defmodule Storybook.Frameworks.Pixel.Button.Action.Send do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.send/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{event: "save"},
        slots: ["Save"]
      }
    ]
  end
end
