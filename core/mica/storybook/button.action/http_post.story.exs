defmodule Storybook.Frameworks.Pixel.Button.Action.HttpPost do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http_post/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/auth/transfer/decline"},
        slots: ["Decline transfer"]
      }
    ]
  end
end
