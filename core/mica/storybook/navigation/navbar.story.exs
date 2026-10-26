defmodule Storybook.Frameworks.Pixel.Navigation.Navbar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.navbar/1

  # Full-width bar: one column and a full-width container keep it inside the variation box.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :default,
        description: "Horizontal top bar: home logo, primary items left, secondary items right",
        attributes: %{
          home: %{
            action: %{type: :redirect, to: "/"},
            face: %{type: :menu_home, icon: :self, size: :wide}
          },
          primary: [
            item(:desktop, "Desktop", active?: true),
            item(:projects, "Projects")
          ],
          secondary: [
            item(:todo, "Todo", counter: 0),
            item(:profile, "Profile")
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
