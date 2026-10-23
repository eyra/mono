defmodule Storybook.Frameworks.Pixel.Image.Blurhash do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Image.blurhash/1

  # Needs the app's `Blurhash` JS hook to paint; without it the div stays empty.
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "project-card-image",
          image: %{
            url: "/images/illustrations/cards.svg",
            width: 640,
            height: 360,
            blur_hash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
          }
        }
      }
    ]
  end
end
