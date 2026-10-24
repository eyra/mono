defmodule Storybook.Frameworks.Pixel.ModalView.Page do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.page/1

  # The bottom Toolbar is a live component, which cannot render inside an iframe story; a scrolling
  # box keeps the fixed-width frame inside the variation box instead.
  def container, do: {:div, class: "w-full h-[640px] overflow-auto"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :settings,
        description: "Page-width modal (960px) with the bottom toolbar",
        attributes: %{
          socket: nil,
          toolbar_buttons: [
            %{action: %{type: :send, event: "save"}, face: %{type: :primary, label: "Save"}},
            %{
              action: %{type: :send, event: "preview"},
              face: %{type: :secondary, label: "Preview"}
            }
          ],
          modal:
            modal(:page,
              heading: "Edit questionnaire",
              text: "Add the link to your survey and set the expected duration.",
              detail:
                "Participants are redirected back automatically when they finish the survey."
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
