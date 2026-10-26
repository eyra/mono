defmodule Storybook.Frameworks.Pixel.Navigation.MobileNavbar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.mobile_navbar/1

  # Full-width bar: one column and a full-width container keep it inside the variation box.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  # The component is only visible below the lg breakpoint; the template forces it visible at any viewport width.
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
        description: "Top bar on a grey background with side padding",
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
