defmodule Storybook.Frameworks.Pixel.Navigation.DesktopMenu do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.desktop_menu/1

  def container, do: {:div, class: "h-[560px]"}

  # The component is only visible from the lg breakpoint; the template forces it visible at any viewport width.
  def template do
    """
    <div class="psb-force-visible h-full" psb-code-hidden>
      <style>.psb-force-visible > div { display: block !important; }</style>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Desktop side menu: wide logo, titled items, secondary items at the bottom",
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
