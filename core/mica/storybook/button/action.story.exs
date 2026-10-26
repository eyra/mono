defmodule Storybook.Frameworks.Pixel.Button.Action do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.action/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{type: :send, event: "save"},
        slots: ["Click to save"]
      }
    ]
  end
end
