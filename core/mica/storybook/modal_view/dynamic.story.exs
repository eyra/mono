defmodule Storybook.Frameworks.Pixel.ModalView.Dynamic do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.dynamic/1

  # The modal is position: fixed over the whole viewport, so each variation gets its own iframe.
  def container, do: {:iframe, style: "width: 100%; height: 560px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :compact,
        description: "Open modal: blurred backdrop with a :compact frame",
        attributes: %{
          socket: nil,
          modal:
            modal(:compact,
              heading: "Delete this project?",
              text: "\"Social media use and wellbeing\" and its 4 assignments will be removed.",
              detail: "This cannot be undone."
            )
        }
      },
      %Variation{
        id: :sheet,
        description: "Open modal with the :sheet preset and a context line",
        attributes: %{
          socket: nil,
          modal:
            modal(:sheet,
              context: "Social media use and wellbeing",
              heading: "Informed consent",
              text:
                "You are invited to take part in a study on how social media use relates to wellbeing.",
              detail: "Participation takes about 15 minutes. You can stop at any moment."
            )
        }
      },
      %Variation{
        id: :no_modal,
        description: "modal={nil} renders nothing",
        attributes: %{socket: nil, modal: nil}
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
