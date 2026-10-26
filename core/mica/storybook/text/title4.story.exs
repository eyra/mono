defmodule Storybook.Frameworks.Pixel.Text.Title4 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title4/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Data donation"]
      }
    ]
  end
end
