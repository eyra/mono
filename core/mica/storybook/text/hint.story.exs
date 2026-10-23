defmodule Storybook.Frameworks.Pixel.Text.Hint do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.hint/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Use at least 12 characters, including a number."]
      }
    ]
  end
end
