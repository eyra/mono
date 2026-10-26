defmodule Storybook.Frameworks.Pixel.Dropdown.Options do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Dropdown.options/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          options: [%{label: "Questionnaire"}, %{label: "Data donation"}, %{label: "Instruction"}],
          target: nil
        },
        slots: []
      }
    ]
  end
end
