defmodule Storybook.Frameworks.Pixel.Button.Action.Label do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.label/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{field: "avatar_upload"},
        slots: ["Choose photo"]
      }
    ]
  end
end
