defmodule Storybook.Frameworks.Pixel.Button.Delete do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.delete/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Delete account", path: "/user/settings"},
        slots: []
      }
    ]
  end
end
