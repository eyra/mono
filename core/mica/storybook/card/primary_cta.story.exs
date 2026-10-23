defmodule Storybook.Frameworks.Pixel.Card.PrimaryCta do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Card.primary_cta/1

  def template do
    """
    <div class="w-96"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Dark call-to-action card",
        attributes: %{
          title: "Ready to start your own study?",
          to: "/",
          button_label: "Get started"
        }
      },
      %VariationGroup{
        id: :button_colors,
        description: "Button background colors",
        variations: [
          %Variation{
            id: :white,
            description: "bg-white (default)",
            attributes: %{title: "Join our participant panel", to: "/", button_label: "Sign up"}
          },
          %Variation{
            id: :tertiary,
            description: "bg-tertiary",
            attributes: %{
              title: "Join our participant panel",
              to: "/",
              button_label: "Sign up",
              button_bg_color: "bg-tertiary"
            }
          }
        ]
      }
    ]
  end
end
