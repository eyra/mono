defmodule Storybook.Frameworks.Pixel.Content.Item do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Content.item/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "Lorem ipsum",
          path: "Lorem ipsum",
          title: "Lorem ipsum",
          subtitle: "Lorem ipsum",
          quick_summary: "Lorem ipsum"
        },
        slots: []
      }
    ]
  end
end
