defmodule Storybook.Frameworks.Pixel.Text.Body do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.body/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: [
          "Your answers are stored securely and only shared with the research team of this study."
        ]
      }
    ]
  end
end
