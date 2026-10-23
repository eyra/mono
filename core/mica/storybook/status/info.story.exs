defmodule Storybook.Frameworks.Pixel.Status.Info do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Status.info/1

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
