defmodule Storybook.Frameworks.Pixel.ModalView.Content do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.content/1

  # Modal frames have fixed widths and centred layouts; an iframe keeps them inside the variation box.
  def container, do: {:iframe, style: "height: 400px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :visible,
        description: "Centres the frame of a visible modal (here the :compact style)",
        attributes: %{
          socket: nil,
          modal:
            modal(:compact,
              heading: "Leave this page?",
              text: "Your answers have been saved. You can continue later from your desktop.",
              detail: "The assignment stays open until the deadline on 1 December."
            )
        }
      }
    ]
  end

  def body(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <Frameworks.Pixel.Text.title3 :if={@heading}>{@heading}</Frameworks.Pixel.Text.title3>
      <Frameworks.Pixel.Text.body_large>{@text}</Frameworks.Pixel.Text.body_large>
      <Frameworks.Pixel.Text.body>{@detail}</Frameworks.Pixel.Text.body>
    </div>
    """
  end

  defp modal(style, opts) do
    element =
      LiveNest.Element.prepare_component(:storybook_modal, &__MODULE__.body/1,
        heading: opts[:heading],
        text: opts[:text],
        detail: opts[:detail]
      )

    %LiveNest.Modal{style: style, visible: true, element: element, options: []}
  end
end
