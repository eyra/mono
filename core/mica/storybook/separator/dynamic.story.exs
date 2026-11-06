defmodule Frameworks.Storybook.Pixel.Separator.Dynamic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Separator.dynamic/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{type: nil},
        slots: []
      }
    ]
  end
end
