defmodule Storybook.Frameworks.Pixel.LoadingSpinner.Secondary do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.LoadingSpinner.secondary/1

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
