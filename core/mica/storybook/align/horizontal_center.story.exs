defmodule Storybook.Frameworks.Pixel.Align.HorizontalCenter do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Align.horizontal_center/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Lorem ipsum"]
      }
    ]
  end
end
