defmodule Storybook.Frameworks.Pixel.SidePanel.SidePanel do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.SidePanel.side_panel/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: nil, parent: nil},
        slots: ["Lorem ipsum"]
      }
    ]
  end
end
