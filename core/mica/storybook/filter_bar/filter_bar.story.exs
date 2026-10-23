defmodule Storybook.Frameworks.Pixel.FilterBar.FilterBar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.FilterBar.filter_bar/1

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
