defmodule Storybook.Frameworks.Pixel.Text.Footnote do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.footnote/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["* Rewards are paid out within 30 days after the study closes."]
      }
    ]
  end
end
