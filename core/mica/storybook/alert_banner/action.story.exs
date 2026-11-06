defmodule Frameworks.Storybook.Pixel.AlertBanner.Action do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.AlertBanner.action/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
