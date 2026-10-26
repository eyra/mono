defmodule Storybook.Frameworks.Pixel.ModalView.Background do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ModalView.background/1

  # The backdrop is position: fixed over the whole viewport, so each variation gets its own iframe.
  def container, do: {:iframe, style: "width: 100%; height: 400px;"}

  def variations do
    [
      %Variation{
        id: :visible,
        description: "Blurred, darkened backdrop behind a modal",
        attributes: %{visible: true},
        slots: [
          """
          <div class="flex items-center justify-center w-full h-full">
            <div class="bg-white rounded shadow-floating p-8 font-body text-bodylarge">Your changes have been saved.</div>
          </div>
          """
        ]
      },
      %Variation{
        id: :hidden,
        description: "visible={false} (default) hides the backdrop and its content",
        attributes: %{visible: false},
        slots: ["Your changes have been saved."]
      }
    ]
  end
end
