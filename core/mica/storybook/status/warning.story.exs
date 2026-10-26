defmodule Storybook.Frameworks.Pixel.Status.Warning do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Status.warning/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{text: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
