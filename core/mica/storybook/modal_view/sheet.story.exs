defmodule Storybook.Frameworks.Pixel.ModalView.Sheet do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.sheet/1

  # Modal frames have fixed widths and centred layouts; an iframe keeps them inside the variation box.
  def container, do: {:iframe, style: "height: 560px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :consent,
        description:
          "Sheet with a grey context line (element option :context) and a close button",
        attributes: %{
          socket: nil,
          modal:
            modal(:sheet,
              context: "Social media use and wellbeing",
              heading: "Informed consent",
              text:
                "You are invited to take part in a study on how social media use relates to wellbeing.",
              detail:
                "Participation takes about 15 minutes. You can stop at any moment without giving a reason, and your data is stored securely for 10 years."
            )
        }
      },
      %Variation{
        id: :without_context,
        description: "Sheet without context line",
        attributes: %{
          socket: nil,
          modal:
            modal(:sheet,
              heading: "Privacy statement",
              text: "We only collect the data you choose to donate.",
              detail: "Your donation is pseudonymised before researchers can access it."
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
        context: opts[:context],
        heading: opts[:heading],
        text: opts[:text],
        detail: opts[:detail]
      )

    %LiveNest.Modal{style: style, visible: true, element: element, options: []}
  end
end
