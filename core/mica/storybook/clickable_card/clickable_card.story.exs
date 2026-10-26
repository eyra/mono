defmodule Storybook.Frameworks.Pixel.ClickableCard.ClickableCard do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ClickableCard.clickable_card/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: 1},
        slots: ["Survey on media use: 15 minutes, 120 participants"]
      }
    ]
  end
end
