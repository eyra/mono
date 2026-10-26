defmodule Storybook.Frameworks.Pixel.Spinner.Static do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Spinner.static/1

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
