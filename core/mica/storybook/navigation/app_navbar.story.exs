defmodule Storybook.Frameworks.Pixel.Navigation.AppNavbar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.app_navbar/1

  # Full-width bar: one column and a full-width container keep it inside the variation box.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :default,
        description: "Product logo followed by a navbar built from the :items map",
        attributes: %{
          logo: :self,
          items: %{
            primary: [
              item(:desktop, "Desktop", active?: true),
              item(:projects, "Projects")
            ],
            secondary: [
              item(:profile, "Profile")
            ]
          }
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
