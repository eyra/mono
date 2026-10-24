defmodule Storybook.Frameworks.Pixel.Button.Action.HttpNew do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http_new/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/project"},
        slots: ["New project"]
      }
    ]
  end
end
