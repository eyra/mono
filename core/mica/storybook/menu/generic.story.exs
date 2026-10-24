defmodule Storybook.Frameworks.Pixel.Menu.Generic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Menu.generic/1

  def container, do: {:div, class: "h-[480px] w-[296px]"}

  def variations do
    [
      %Variation{
        id: :side_menu,
        description: "Home logo, primary items on top and secondary items pushed to the bottom",
        attributes: %{
          home: %{
            action: %{type: :redirect, to: "/"},
            face: %{type: :menu_home, icon: :self, size: :wide}
          },
          primary: [
            item(:desktop, "Desktop", active?: true),
            item(:projects, "Projects"),
            item(:todo, "Todo", counter: 3)
          ],
          secondary: [
            item(:support, "Support"),
            item(:profile, "Profile"),
            item(:signout, "Sign out")
          ]
        }
      }
    ]
  end

  defp item(icon, title, opts \\ []) do
    %{
      action: %{type: :redirect, to: "/#{icon}"},
      face: %{
        type: :menu_item,
        icon: icon,
        title: title,
        active?: Keyword.get(opts, :active?, false),
        counter: opts[:counter]
      }
    }
  end
end
