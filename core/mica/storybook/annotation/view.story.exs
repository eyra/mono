defmodule Storybook.Frameworks.Pixel.Annotation.View do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Annotation.view/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{annotation: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
