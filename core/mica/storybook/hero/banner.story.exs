defmodule Storybook.Frameworks.Pixel.Hero.Banner do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Hero.banner/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{icon_url: "Lorem ipsum"},
        slots: []
      }
    ]
  end
end
