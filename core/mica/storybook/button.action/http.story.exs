defmodule Storybook.Frameworks.Pixel.Button.Action.Http do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/user/session", method: "delete"},
        slots: ["Sign out"]
      }
    ]
  end
end
