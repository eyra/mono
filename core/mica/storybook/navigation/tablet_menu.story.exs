defmodule Storybook.Frameworks.Pixel.Navigation.TabletMenu do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.tablet_menu/1

  def container, do: {:div, class: "h-[480px]"}

  # The component is only visible between the md and lg breakpoints; the template forces it visible at any viewport width.
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
        description: "Tablet side menu: square logo and icon-only items, centred",
        attributes: %{
          home: %{
            action: %{type: :redirect, to: "/"},
            face: %{type: :menu_home, icon: :self, size: :default}
          },
          primary: [
            item(:desktop, nil, active?: true),
            item(:projects, nil),
            item(:todo, nil, counter: nil)
          ],
          secondary: [
            item(:support, nil),
            item(:profile, nil),
            item(:signout, nil)
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
