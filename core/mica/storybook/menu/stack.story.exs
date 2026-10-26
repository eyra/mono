defmodule Storybook.Frameworks.Pixel.Menu.Stack do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Menu.stack/1

  def variations do
    [
      %Variation{
        id: :primary,
        description: "Vertical stack of menu items, first one active",
        attributes: %{
          items: [
            item(:desktop, "Desktop", active?: true),
            item(:projects, "Projects"),
            item(:todo, "Todo", counter: 3),
            item(:helpdesk, "Helpdesk")
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
