defmodule Storybook.Frameworks.Pixel.Text.Title3 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title3/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Recruitment criteria"]
      }
    ]
  end
end
