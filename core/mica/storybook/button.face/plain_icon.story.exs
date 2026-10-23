defmodule Storybook.Frameworks.Pixel.Button.Face.PlainIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.plain_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Next step"},
        slots: []
      }
    ]
  end
end
