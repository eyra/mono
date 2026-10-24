defmodule Storybook.Frameworks.Pixel.Text.Title2 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title2/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Study settings"]
      }
    ]
  end
end
