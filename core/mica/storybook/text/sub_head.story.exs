defmodule Storybook.Frameworks.Pixel.Text.SubHead do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.sub_head/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Social media and wellbeing study"]
      }
    ]
  end
end
