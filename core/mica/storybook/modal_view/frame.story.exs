defmodule Storybook.Frameworks.Pixel.ModalView.Frame do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.frame/1

  # Modal frames have fixed widths and centred layouts; an iframe keeps them inside the variation box.
  def container, do: {:iframe, style: "height: 560px;"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :compact,
        description: "Legacy style :compact (delegates to compact/1)",
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
        id: :sheet_preset,
        description:
          "Preset :sheet (wide, tall, scrollable, close control, context line from :context)",
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
        id: :aspects_with_actions,
        description:
          "Explicit aspects [controls: :actions, width: :narrow]: buttons centred below the body",
        attributes: %{
          socket: nil,
          toolbar_buttons: [
            %{
              action: %{type: :send, event: "confirm"},
              face: %{type: :primary, label: "Publish"}
            },
            %{action: %{type: :send, event: "cancel"}, face: %{type: :label, label: "Cancel"}}
          ],
          modal:
            modal([controls: :actions, width: :narrow],
              heading: "Publish assignment?",
              text: "Participants in the selected pool can join as soon as it is published.",
              detail: "You can close the assignment at any time."
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
