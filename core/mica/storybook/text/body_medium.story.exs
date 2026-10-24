defmodule Storybook.Frameworks.Pixel.Text.BodyMedium do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.body_medium/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Participation takes about 15 minutes and you can stop at any moment."]
      }
    ]
  end
end
