defmodule Storybook.Frameworks.Pixel.Button.Primary do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.primary/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Get started", to: "/user/signup"},
        slots: []
      }
    ]
  end
end
