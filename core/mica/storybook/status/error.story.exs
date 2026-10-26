defmodule Storybook.Frameworks.Pixel.Status.Error do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Status.error/1

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
