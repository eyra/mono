defmodule Storybook.Frameworks.Pixel.Logo.Platform do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Logo.platform/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{platform: nil},
        slots: []
      }
    ]
  end
end
