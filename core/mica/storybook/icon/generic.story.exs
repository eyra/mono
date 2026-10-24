defmodule Storybook.Frameworks.Pixel.Icon.Generic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Icon.generic/1

  def variations do
    [
      %Variation{
        id: :static,
        attributes: %{type: :static, src: "projects", size: "h-14 w-14"}
      },
      %Variation{
        id: :url,
        attributes: %{
          type: :url,
          src: "/images/icons/placeholder_square.svg",
          size: "h-14 w-14",
          border_radius: "rounded-lg"
        }
      },
      %Variation{
        id: :emoji,
        attributes: %{type: :emoji, src: "🧪", size: "L"}
      }
    ]
  end
end
