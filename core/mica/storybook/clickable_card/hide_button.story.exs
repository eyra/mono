defmodule Storybook.Frameworks.Pixel.ClickableCard.HideButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ClickableCard.hide_button/1

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
