defmodule Storybook.Frameworks.Pixel.Text.Intro do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.intro/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Help science forward by sharing how you use social media in daily life."]
      }
    ]
  end
end
