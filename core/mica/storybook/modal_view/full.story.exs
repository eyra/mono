defmodule Storybook.Frameworks.Pixel.ModalView.Full do
  use PhoenixStorybook.Story, :component
  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Frameworks.Pixel.ModalView.full/1

  # The bottom Toolbar is a live component, which cannot render inside an iframe story; a scrolling
  # box keeps the fixed-width frame inside the variation box instead.
  def container, do: {:div, class: "w-full h-[640px] overflow-auto"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :settings,
        description:
          "Full modal with an optional context header (element option :header) and the bottom toolbar",
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
            modal(:full,
              header: "Social media use and wellbeing",
              heading: "Assignment settings",
              text: "Configure who can join this assignment and how many participants you need.",
              detail: "Changes are saved automatically and apply to new participants only."
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
        header: opts[:header],
        heading: opts[:heading],
        text: opts[:text],
        detail: opts[:detail]
      )

    %LiveNest.Modal{style: style, visible: true, element: element, options: []}
  end
end
