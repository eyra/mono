defmodule Storybook.Frameworks.Pixel.Line.Line do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Line.line/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: []
      }
    ]
  end
end
