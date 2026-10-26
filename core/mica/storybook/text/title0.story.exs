defmodule Storybook.Frameworks.Pixel.Text.Title0 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title0/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Research made easy"]
      }
    ]
  end
end
