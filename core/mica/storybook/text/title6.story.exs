defmodule Storybook.Frameworks.Pixel.Text.Title6 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title6/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Contact information"]
      }
    ]
  end
end
