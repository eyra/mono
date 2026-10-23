defmodule Storybook.Frameworks.Pixel.Button.Back do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.back/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Projects", path: "/project"},
        slots: []
      }
    ]
  end
end
