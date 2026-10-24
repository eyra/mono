defmodule Storybook.Frameworks.Pixel.Button.Action.HttpDelete do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http_delete/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/user/session"},
        slots: ["Sign out"]
      }
    ]
  end
end
