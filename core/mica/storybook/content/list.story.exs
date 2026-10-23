defmodule Storybook.Frameworks.Pixel.Content.List do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Content.list/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{items: []},
        slots: []
      }
    ]
  end
end
