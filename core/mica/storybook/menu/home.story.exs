defmodule Storybook.Frameworks.Pixel.Menu.Home do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Menu.home/1

  def variations do
    [
      %Variation{
        id: :wide,
        description: "Home item with the wide product logo",
        attributes: %{
          action: %{type: :redirect, to: "/"},
          face: %{type: :menu_home, icon: :self, size: :wide}
        }
      },
      %Variation{
        id: :narrow,
        description: "Home item with the square product logo (tablet menu)",
        attributes: %{
          action: %{type: :redirect, to: "/"},
          face: %{type: :menu_home, icon: :self, size: :default}
        }
      }
    ]
  end
end
