defmodule Storybook.Frameworks.Pixel.Button.Action.Toggle do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.toggle/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "menu_toggle", target: "mobile_menu"},
        slots: ["Menu"]
      }
    ]
  end
end
