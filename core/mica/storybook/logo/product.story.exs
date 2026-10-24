defmodule Storybook.Frameworks.Pixel.Logo.Product do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Logo.product/1

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
