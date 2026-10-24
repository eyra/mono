defmodule Storybook.Frameworks.Pixel.Button.PrimaryWide do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.primary_wide/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Continue", to: "/project", bg_color: "bg-primary"},
        slots: []
      }
    ]
  end
end
