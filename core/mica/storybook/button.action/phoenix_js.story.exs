defmodule Storybook.Frameworks.Pixel.Button.Action.PhoenixJs do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.phoenix_js/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{js: JS.toggle(to: "#details")},
        slots: ["Toggle details"]
      }
    ]
  end
end
