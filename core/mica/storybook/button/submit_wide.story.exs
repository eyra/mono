defmodule Storybook.Frameworks.Pixel.Button.SubmitWide do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.submit_wide/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Create account"},
        slots: []
      }
    ]
  end
end
