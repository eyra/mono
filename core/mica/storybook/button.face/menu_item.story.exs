defmodule Storybook.Frameworks.Pixel.Button.Face.MenuItem do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.menu_item/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Inbox", counter: 3, icon: :inbox},
        slots: []
      }
    ]
  end
end
