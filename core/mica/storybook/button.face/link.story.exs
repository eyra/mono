defmodule Storybook.Frameworks.Pixel.Button.Face.Link do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Face.link/1

  # `<.link>` clashes with the imported `Phoenix.Component.link/1`, so the
  # templates call the component by its alias instead of the `.psb-variation` placeholder.
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{text: "Show details"},
        template: ~s(<Face.link text="Show details" />)
      },
      %Variation{
        id: :custom_font,
        attributes: %{text: "Read the privacy statement", font: "text-bodysmall font-body"},
        template:
          ~s(<Face.link text="Read the privacy statement" font="text-bodysmall font-body" />)
      }
    ]
  end
end
