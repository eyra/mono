defmodule Storybook.Frameworks.Pixel.Text.Caption do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.caption/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Figure 1. Average screen time per day, by age group"]
      }
    ]
  end
end
