defmodule Storybook.Frameworks.Pixel.Hero.LandingPage do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.landing_page/1

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
