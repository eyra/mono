defmodule Storybook.Frameworks.Pixel.Annotation.Panel do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Annotation.panel/1

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
