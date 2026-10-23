defmodule Storybook.Frameworks.Pixel.Button.Action.Redirect do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.redirect/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/project"},
        slots: ["Go to projects"]
      }
    ]
  end
end
