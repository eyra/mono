defmodule Storybook.Frameworks.Pixel.Icon.Square do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Icon.square/1

  def variations do
    [
      %Variation{
        id: :static,
        attributes: %{type: :static, src: "projects"}
      },
      %Variation{
        id: :emoji,
        attributes: %{type: :emoji, src: "📊"}
      }
    ]
  end
end
