defmodule Storybook.Frameworks.Pixel.Status.Generic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Status.generic/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          text: "Lorem ipsum",
          text_color: "Lorem ipsum",
          bg_color: "Lorem ipsum",
          bg_opacity: "Lorem ipsum"
        },
        slots: []
      }
    ]
  end
end
