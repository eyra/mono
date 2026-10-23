defmodule Storybook.Frameworks.Pixel.LoadingSpinner.Primary do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.LoadingSpinner.primary/1

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
