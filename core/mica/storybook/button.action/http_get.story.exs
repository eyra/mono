defmodule Storybook.Frameworks.Pixel.Button.Action.HttpGet do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http_get/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/project"},
        slots: ["Open projects"]
      }
    ]
  end
end
