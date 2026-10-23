defmodule Storybook.Frameworks.Pixel.Dropdown.Option do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Dropdown.option/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{index: 0, label: "Questionnaire", target: nil}
      }
    ]
  end
end
