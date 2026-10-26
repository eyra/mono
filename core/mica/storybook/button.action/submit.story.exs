defmodule Storybook.Frameworks.Pixel.Button.Action.Submit do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.submit/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Submit form"]
      }
    ]
  end
end
