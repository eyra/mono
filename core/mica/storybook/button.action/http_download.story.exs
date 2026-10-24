defmodule Storybook.Frameworks.Pixel.Button.Action.HttpDownload do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.Action.http_download/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{to: "/images/icons/export.svg"},
        slots: ["Download export"]
      }
    ]
  end
end
