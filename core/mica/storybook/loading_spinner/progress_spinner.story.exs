defmodule Storybook.Frameworks.Pixel.LoadingSpinner.ProgressSpinner do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.LoadingSpinner.progress_spinner/1

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
