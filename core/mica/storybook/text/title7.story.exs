defmodule Storybook.Frameworks.Pixel.Text.Title7 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title7/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Last updated"]
      }
    ]
  end
end
