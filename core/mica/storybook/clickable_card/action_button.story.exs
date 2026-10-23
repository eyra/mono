defmodule Storybook.Frameworks.Pixel.ClickableCard.ActionButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ClickableCard.action_button/1

  # The wrapper is `hidden` until the card's hover JS reveals it, so the preview is empty.
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          index: 0,
          position: :right,
          card_id: 1,
          button: %{
            action: %{type: :send, event: "delete", item: "1"},
            face: %{type: :icon, icon: :delete}
          }
        }
      }
    ]
  end
end
