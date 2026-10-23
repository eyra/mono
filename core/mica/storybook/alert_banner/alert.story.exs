defmodule Storybook.Frameworks.Pixel.AlertBanner.Alert do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.AlertBanner.alert/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Lorem ipsum"]
      }
    ]
  end
end
