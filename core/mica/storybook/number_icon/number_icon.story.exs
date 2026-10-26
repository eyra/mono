defmodule Storybook.Frameworks.Pixel.NumberIcon.NumberIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.NumberIcon.number_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{number: 1},
        slots: []
      }
    ]
  end
end
