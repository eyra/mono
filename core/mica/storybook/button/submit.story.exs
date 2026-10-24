defmodule Storybook.Frameworks.Pixel.Button.Submit do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.submit/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Sign in"},
        slots: []
      }
    ]
  end
end
