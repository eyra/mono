defmodule Storybook.Frameworks.Pixel.Button.Action.Fake do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.fake/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Looks clickable, does nothing"]
      }
    ]
  end
end
