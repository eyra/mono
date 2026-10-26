defmodule Storybook.Frameworks.Pixel.Text.BodySmall do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.body_small/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["By continuing you agree to the terms of participation."]
      }
    ]
  end
end
