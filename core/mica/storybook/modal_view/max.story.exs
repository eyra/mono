defmodule Storybook.Frameworks.Pixel.ModalView.Max do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.max/1

  # Modal frames have fixed widths and centred layouts; an iframe keeps them inside the variation box.
  def container, do: {:iframe, style: "height: 560px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :preview,
        description:
          "Maximised modal: title header (element option :title), close button and minimal padding",
        attributes: %{
          socket: nil,
          modal:
            modal(:max,
              title: "Data donation preview",
              text: "This is how participants see the data donation flow on their device.",
              detail:
                "Step 1: request your data package. Step 2: upload the file. Step 3: review and donate."
            )
        }
      }
    ]
  end

  def body(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 pt-4">
      <Frameworks.Pixel.Text.body_large>{@text}</Frameworks.Pixel.Text.body_large>
      <Frameworks.Pixel.Text.body>{@detail}</Frameworks.Pixel.Text.body>
    </div>
    """
  end

  defp modal(style, opts) do
    element =
      LiveNest.Element.prepare_component(:storybook_modal, &__MODULE__.body/1,
        title: opts[:title],
        text: opts[:text],
        detail: opts[:detail]
      )

    %LiveNest.Modal{style: style, visible: true, element: element, options: []}
  end
end
