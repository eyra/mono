defmodule Storybook.Frameworks.Pixel.Text.Bullet do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.bullet/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{image: "/images/bullit.svg"},
        slots: ["Complete the questionnaire within 7 days"]
      }
    ]
  end
end
