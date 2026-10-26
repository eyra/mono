defmodule Storybook.Frameworks.Pixel.Text.Title5 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title5/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Next steps"]
      }
    ]
  end
end
