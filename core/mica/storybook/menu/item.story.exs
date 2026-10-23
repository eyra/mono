defmodule Storybook.Frameworks.Pixel.Menu.Item do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Menu.item/1

  def variations do
    [
      %Variation{
        id: :active,
        description: "Active menu item: grey pill and active icon",
        attributes: item(:desktop, "Desktop", active?: true)
      },
      %Variation{
        id: :idle,
        description: "Idle menu item",
        attributes: item(:projects, "Projects")
      },
      %Variation{
        id: :with_counter,
        description: "Menu item with a counter badge (0 renders green)",
        attributes: item(:todo, "Todo", counter: 3)
      },
      %Variation{
        id: :icon_only,
        description: "Icon without title, as used in the tablet menu",
        attributes: item(:support, nil)
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
