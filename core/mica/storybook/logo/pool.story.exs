defmodule Storybook.Frameworks.Pixel.Logo.Pool do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Logo.pool/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{name: nil},
        slots: []
      }
    ]
  end
end
