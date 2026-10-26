defmodule Storybook.Frameworks.Pixel.ModalView.Compact do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.compact/1

  # Modal frames have fixed widths and centred layouts; an iframe keeps them inside the variation box.
  def container, do: {:iframe, style: "height: 400px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :delete_confirmation,
        description: "Compact dialog with a floating close button, used for confirmations",
        attributes: %{
          socket: nil,
          modal:
            modal(:compact,
              heading: "Delete this project?",
              text: "\"Social media use and wellbeing\" and its 4 assignments will be removed.",
              detail:
                "Participants who already donated data keep their receipts. This cannot be undone."
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
        title: opts[:title],
        context: opts[:context],
        header: opts[:header],
        heading: opts[:heading],
        text: opts[:text],
        detail: opts[:detail]
      )

    %LiveNest.Modal{style: style, visible: true, element: element, options: []}
  end
end
