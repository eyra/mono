defmodule Storybook.Frameworks.Pixel.Icon.GenericBody do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Icon.generic_body/1

  def variations do
    [
      %Variation{
        id: :static,
        attributes: %{type: :static, src: "projects", size: "S"}
      },
      %Variation{
        id: :url,
        attributes: %{
          type: :url,
          src: "/images/icons/placeholder_square.svg",
          size: "S",
          border_radius: "rounded-lg"
        }
      },
      %Variation{
        id: :emoji,
        attributes: %{type: :emoji, src: "🧪", size: "M"}
      }
    ]
  end
end
