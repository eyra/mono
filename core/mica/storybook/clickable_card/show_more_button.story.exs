defmodule Storybook.Frameworks.Pixel.ClickableCard.ShowMoreButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ClickableCard.show_more_button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{card_id: 1},
        slots: []
      }
    ]
  end
end
